$ErrorActionPreference = "Stop"

# List of Terraform modules to apply in sequence
$targets = @(
    "module.vpc",
    "module.eks",
    "module.karpenter",
    "module.argocd"
)

# Initialize Terraform
terraform init -upgrade

$terraformCommand = "terraform apply -auto-approve"

# Check if blueprint.tfvars exists
if (Test-Path "..\blueprint.tfvars") {
    $terraformCommand += " -var-file=..\blueprint.tfvars"
}

# Apply modules in sequence
foreach ($target in $targets) {
    Write-Host "Applying module $target..."
    
    # We use Invoke-Expression or direct execution. Direct is safer but parsing arguments with spaces/quotes can be tricky.
    # Since we are constructing a command string, Invoke-Expression is easiest for porting exact string logic,
    # but strictly passed arguments are better.
    # Let's verify the command structure: "terraform apply -auto-approve -var-file=..." -target="..."
    
    # Using arrays for arguments is cleaner in PowerShell
    $argsList = @("apply", "-auto-approve")
    if (Test-Path "..\blueprint.tfvars") {
        $argsList += "-var-file=..\blueprint.tfvars"
    }
    $argsList += "-target=$target"
    
    Write-Host "Running: terraform $argsList"
    & terraform $argsList
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Terraform apply of $target completed successfully" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Terraform apply of $target failed" -ForegroundColor Red
        exit 1
    }
}

# Final apply to catch any remaining resources
Write-Host "Applying remaining resources..."
$argsList = @("apply", "-auto-approve")
if (Test-Path "..\blueprint.tfvars") {
    $argsList += "-var-file=..\blueprint.tfvars"
}

Write-Host "Running: terraform $argsList"
& terraform $argsList

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Terraform apply of all modules completed successfully" -ForegroundColor Green
} else {
    Write-Host "FAILED: Terraform apply of all modules failed" -ForegroundColor Red
    exit 1
}
