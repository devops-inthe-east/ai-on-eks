
# Specs for G5 instances
$g5_large = @{ Name="g5.large"; GPU=1; CPU=2; MemGiB=8 }
$g5_2xlarge = @{ Name="g5.2xlarge"; GPU=1; CPU=8; MemGiB=32 }

# Get all pods
$pods = kubectl get pods -A -o json | ConvertFrom-Json

$results = @()

foreach ($pod in $pods.items) {
    if (!$pod.spec.containers) { continue }
    
    foreach ($container in $pod.spec.containers) {
        $req = $container.resources.requests
        if ($req."nvidia.com/gpu") {
            $gpu = [int]$req."nvidia.com/gpu"
            $cpu = $req.cpu
            $mem = $req.memory
            
            # Normalize CPU (milli-cores to cores)
            if ($cpu -match "m$") { $cpuDir = [double]($cpu -replace "m","") / 1000 }
            else { $cpuDir = [double]$cpu }
            
            # Normalize Memory (Mi/Gi to GiB)
            # This is a rough conversion for display
            if ($mem -match "Gi") { $memDir = [double]($mem -replace "Gi","") }
            elseif ($mem -match "Mi") { $memDir = [double]($mem -replace "Mi","") / 1024 }
            else { $memDir = 0 }

            # Checking Fit
            $fitLarge = ($gpu -le $g5_large.GPU) -and ($cpuDir -le $g5_large.CPU) -and ($memDir -le $g5_large.MemGiB)
            $fit2xl = ($gpu -le $g5_2xlarge.GPU) -and ($cpuDir -le $g5_2xlarge.CPU) -and ($memDir -le $g5_2xlarge.MemGiB)
            
            $status = if ($fitLarge) { "Fits g5.large" } 
                      elseif ($fit2xl) { "Fits g5.2xlarge" } 
                      else { "TOO BIG" }

            $results += [PSCustomObject]@{
                Pod = "$($pod.metadata.namespace)/$($pod.metadata.name)"
                Container = $container.name
                GPU = $gpu
                CPU = $cpuDir
                RAM_GiB = "{0:N2}" -f $memDir
                Status = $status
            }
        }
    }
}

$results | Format-Table -AutoSize | Out-String | Write-Host
