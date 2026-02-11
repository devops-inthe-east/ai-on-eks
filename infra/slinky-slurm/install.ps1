<#
    SICP PRINCIPLE: Means of Abstraction
    This entire script serves as a procedural abstraction.
    It encapsulates the logic of "setting up and running a local terraform modules"
    so the user only needs to invoke "install.ps1".
#>

# SICP PRINCIPLE: Primitives
# SICP distinguishes between two types of primitives:
# 1. Primitive Data: The things we manipulate. 
#    - Examples: "Stop", ".\terraform\_LOCAL" (Strings), $true/$false (Booleans).
# 2. Primitive Procedures: The built-in rules for manipulating data.
#    - Examples: New-Item, Copy-Item, Set-Location (Built-in Cmdlets).
#
# $ErrorActionPreference is a built-in name binding that controls environment behavior.
$ErrorActionPreference = "Stop"

# Copy the base into the folder
# SICP PRINCIPLE: Means of Combination (Composition)
# Here we combine primitives (New-Item) and data (strings) to perform an action.
# The pipe operator '|' is a powerful combination mechanism, passing output from one process to another.
New-Item -ItemType Directory -Force -Path ".\terraform\_LOCAL" | Out-Null
Copy-Item -Recurse -Force "..\base\terraform\*" ".\terraform\_LOCAL"

Set-Location "terraform\_LOCAL"

# Execute the inner install script
# SICP PRINCIPLE: Means of Combination (Control Flow)
# The 'if' statement combines a predicate (Test-Path) with a consequence (execution block).
if (Test-Path ".\install.ps1") {
    .\install.ps1
} elseif (Test-Path ".\install.sh") {
    # Fallback if ps1 doesn't exist but sh does (unlikely given we just made it, but good resilience)
    Write-Warning "install.ps1 not found, attempting to run install.sh via bash..."
    bash .\install.sh
} else {
    Write-Error "No install script found in terraform\_LOCAL"
    exit 1
}
