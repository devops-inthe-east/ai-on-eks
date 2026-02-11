$n = kubectl get nodepools -o json | ConvertFrom-Json
$n.items | ForEach-Object {
    $req = $_.spec.template.spec.requirements
    [PSCustomObject]@{
        Name = $_.metadata.name
        NodeClass = $_.spec.template.spec.nodeClassRef.name
        Families = ($req | Where-Object { $_.key -eq "karpenter.k8s.aws/instance-family" }).values -join ", "
        Types = ($req | Where-Object { $_.key -eq "karpenter.k8s.aws/instance-type" }).values -join ", "
        Capacity = ($req | Where-Object { $_.key -eq "karpenter.sh/capacity-type" }).values -join ", "
    }
} | Format-Table -AutoSize
