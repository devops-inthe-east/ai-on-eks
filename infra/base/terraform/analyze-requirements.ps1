
# Get all pods with their spec in JSON format
$pods = kubectl get pods -A -o json | ConvertFrom-Json

# Initialize an array to hold the simplified requirements
$requirements = @()

foreach ($pod in $pods.items) {
    $ns = $pod.metadata.namespace
    $name = $pod.metadata.name
    $owner = if ($pod.metadata.ownerReferences) { $pod.metadata.ownerReferences[0].kind + "/" + $pod.metadata.ownerReferences[0].name } else { "Standalone" }
    
    # Extract Node Selector
    $nodeSelector = if ($pod.spec.nodeSelector) {
        ($pod.spec.nodeSelector.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", "
    } else {
        "None"
    }

    # Extract Tolerations (Key=Value:Effect)
    $tolerations = if ($pod.spec.tolerations) {
        ($pod.spec.tolerations | Where-Object { $_.key -ne "node.kubernetes.io/not-ready" -and $_.key -ne "node.kubernetes.io/unreachable" } | ForEach-Object {
            $key = if ($_.key) { $_.key } else { "*" }
            $op = if ($_.operator) { $_.operator } else { "Equal" }
            $val = if ($_.value) { $_.value } else { "" }
            $eff = if ($_.effect) { $_.effect } else { "All" }
            
            if ($op -eq "Exists") {
                "$key (Exists):$eff"
            } else {
                "$key=$val`:$eff"
            }
        }) -join ", "
    } else {
        "None"
    }
    
    # Simple Affinity Check (Just presence)
    $affinity = if ($pod.spec.affinity.nodeAffinity) { "Present" } else { "None" }

    # detailed affinity 
    $detailedAffinity = if ($pod.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution) {
        $terms = $pod.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms
        ($terms | ForEach-Object {
            $_.matchExpressions | ForEach-Object { "$($_.key) $($_.operator) [$($_.values -join ',')]" }
        }) -join " AND "
    } else {
        "None"
    }

    $requirements += [PSCustomObject]@{
        Namespace = $ns
        Owner = $owner
        NodeSelector = $nodeSelector
        Tolerations = $tolerations
        Affinity = $detailedAffinity
    }
}

# Group by unique requirements to reduce noise
$grouped = $requirements | Group-Object NodeSelector, Tolerations, Affinity | Sort-Object Count -Descending


# Output Report
$report = @()
$report += "Cluster Workload Requirement Analysis"
$report += "====================================="
$report += ""

foreach ($group in $grouped) {
    $sample = $group.Group[0]
    $report += "Profile Count: $($group.Count) pods"
    $report += "  Used By (Sample): $($sample.Namespace)/$($sample.Owner)"
    $report += "  NodeSelector:     $($sample.NodeSelector)"
    $report += "  Tolerations:      $($sample.Tolerations)"
    $report += "  Node Affinity:    $($sample.Affinity)"
    $report += "--------------------------------------------------------"
}

$report | Out-String | Write-Host
