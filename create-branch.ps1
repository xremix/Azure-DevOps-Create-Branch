# Azure DevOps PowerShell Script using Azure CLI
# Lists user stories assigned to the current user with state "In Progress"

param(
    [Parameter(Mandatory=$false)]
    [string]$Organization,

    [Parameter(Mandatory=$false)]
    [string]$Project
)

# Set this to $true to always create a new branch, or $false to check out if it exists
$AlwaysCreateBranch = $false
# Function to get user stories assigned to current user in "In Progress" state
function Get-InProgressUserStories {
    param(
        [string]$org,
        [string]$proj
    )

    # Check if Azure CLI is installed and user is logged in
    try {
        $loginCheck = az account show 2>$null
        if (-not $loginCheck) {
            Write-Host "Checking Azure CLI login status..." -ForegroundColor Yellow
            Write-Error "You are not logged in to Azure CLI. Please run 'az login' first."
            return
        }
    }
    catch {
        Write-Host "Checking Azure CLI login status..." -ForegroundColor Yellow
        Write-Error "Azure CLI is not installed or not accessible. Please install Azure CLI first."
        return
    }

    # Check if Azure DevOps extension is installed
    $extensions = az extension list --query "[?name=='azure-devops'].name" -o tsv 2>$null
    if (-not $extensions -or $extensions -notcontains "azure-devops") {
        Write-Host "Checking Azure DevOps CLI extension..." -ForegroundColor Yellow
        Write-Host "Installing Azure DevOps CLI extension..." -ForegroundColor Yellow
        az extension add --name azure-devops
    }

    # Set default organization and project
    az devops configure --defaults organization=https://dev.azure.com/$org project=$proj
    
    # Get current user information
    # Write-Host "Getting current user information..." -ForegroundColor Yellow
    try {
        $currentUser = az ad signed-in-user show --query "userPrincipalName" -o tsv 2>$null
        if (-not $currentUser) {
            $currentUser = az ad signed-in-user show --query "userPrincipalName" -o tsv 2>$null

        }
        # Write-Host "Current user: $currentUser" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to get current user information: $($_.Exception.Message)"
        return
    }
    

    # Query for user stories assigned to current user in "In Progress" state
    $wiqlQuery = @"
SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.WorkItemType]
FROM WorkItems
WHERE [System.AssignedTo] = '$currentUser'
AND [System.State] != 'Closed'
AND [System.State] != 'On Hold'
AND [System.State] != 'Done'
AND [System.State] != 'Removed'
AND [System.State] != 'Rejected'
AND [System.State] != 'In Production'
AND [System.State] != 'Waiting for Release'
AND [System.State] != 'Ready to Test'
ORDER BY [System.Id]
"@

    try {
        # Execute WIQL query using Azure CLI
        $queryResult = az boards query --wiql $wiqlQuery --output json | ConvertFrom-Json

        if (-not $queryResult -or $queryResult.Count -eq 0) {
            Write-Host "No user stories found assigned to you." -ForegroundColor Green
            return
        }

        # Display results
        Write-Host "$($queryResult.Count) user stories assigned to $currentUser" -ForegroundColor Green
        Write-Host ""

        # Store work items in an array for indexed access
        $workItems = @()
        $index = 1
        foreach ($workItem in $queryResult) {
            $workItems += $workItem
            $id = $workItem.id
            $title = $workItem.fields.'System.Title'
            $state = $workItem.fields.'System.State'
            $workItemType = $workItem.fields.'System.WorkItemType'
            $titleColor = if ($workItemType -eq "Bug") { "Red" } else { "Cyan" }
            Write-Host "$index. ${id}: ${title} [$state]" -ForegroundColor $titleColor
            $index++
        }

        # Ask user for line number
        Write-Host
        $selectedLine = Read-Host "Select User Story"
        if ($selectedLine -match '^[0-9]+$' -and $selectedLine -ge 1 -and $selectedLine -le $workItems.Count) {
            $selectedWorkItem = $workItems[$selectedLine - 1]
            $id = $selectedWorkItem.id
            $title = $selectedWorkItem.fields.'System.Title'
            $workItemType = $selectedWorkItem.fields.'System.WorkItemType'
            # map type, if is not bug, write feature/
            if ($workItemType -eq "Bug") {
                $branchType = "fix"
            } else {
                $branchType = "feature"
            }

            # Clean title: remove special characters except spaces, then replace spaces with hyphens
            $cleanTitle = ($title -replace '[^a-zA-Z0-9 ]', '')
            $cleanTitle = $cleanTitle.ToLower().Replace(' ', '-')
            $branchName = "$branchType/$id-$cleanTitle"
            # cut branch name after 100 chars
            $branchName = $branchName.Substring(0, [Math]::Min($branchName.Length, 100))
            $confirmation = Read-Host "Branch: $branchName (enter to confirm)"

            if (-not [string]::IsNullOrWhiteSpace($confirmation)) {
                $branchName = $confirmation
            }

            # check if branch already exists, if not create it, otherwise checkout
            if ($AlwaysCreateBranch -or -not (git branch --list $branchName)) {
                $env:GIT_LFS_SKIP_SMUDGE = "1"
                git checkout -b $branchName
                $env:GIT_LFS_SKIP_SMUDGE = $null
            } else {
                # Ask user if they want to switch to the branch or create a new one
                Write-Host "Branch '$branchName' already exists" -ForegroundColor Yellow
                $branchChoice = Read-Host "Switch or Create new branch? [S/c]"
                if ($branchChoice -eq 'c') {
                    $newBranchName = "$branchName-2"
                    $env:GIT_LFS_SKIP_SMUDGE = "1"
                    git checkout -b $newBranchName
                    $env:GIT_LFS_SKIP_SMUDGE = $null
                } else {
                    # check out the branch and switch over the open changes
                    git stash
                    git checkout $branchName
                    git stash pop
                }
            }

        } else {
            Write-Host "Invalid number. Please choose a user story from the list above." -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Failed to query work items: $($_.Exception.Message)"
        return
    }
}

# Main execution
# Write-Host "Azure DevOps User Story Query Script (using Azure CLI)" -ForegroundColor Cyan
# Write-Host "======================================================" -ForegroundColor Cyan

function Get-DevOpsProjectFromFile {

    # Try to find git root
    $gitRoot = $null
    try {
        $gitRoot = git rev-parse --show-toplevel 2>$null
    } catch {}

    # Build list of directories to search: current dir up to git root
    $dirs = @((Get-Location).Path)
    if ($gitRoot) {
        $current = (Get-Location).Path
        while ($current -ne $gitRoot) {
            $parent = Split-Path $current -Parent
            if ($parent -and $parent -ne $current) {
                $dirs += $parent
                $current = $parent
            } else {
                break
            }
        }
        $dirs += $gitRoot
    }

    foreach ($dir in $dirs) {
        $filePath = Join-Path $dir ".devops-project"
        if (Test-Path $filePath) {
            $lines = Get-Content $filePath
            $org = $null
            $proj = $null
            foreach ($line in $lines) {
                if ($line -match '^organization=(.+)$') {
                    $org = $Matches[1]
                } elseif ($line -match '^project=(.+)$') {
                    $proj = $Matches[1]
                }
            }
            return @{ Organization = $org; Project = $proj }
        }
    }
    # Fallback: check script folder
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot) { $scriptRoot = (Get-Location).Path }
    $scriptFilePath = Join-Path $scriptRoot ".devops-project"
    if (Test-Path $scriptFilePath) {
        $lines = Get-Content $scriptFilePath
        $org = $null
        $proj = $null
        foreach ($line in $lines) {
            if ($line -match '^organization=(.+)$') {
                $org = $Matches[1]
            } elseif ($line -match '^project=(.+)$') {
                $proj = $Matches[1]
            }
        }
        return @{ Organization = $org; Project = $proj }
    }
    return $null
}

# Validate parameters or read from .devops-project file
if ([string]::IsNullOrWhiteSpace($Organization) -or [string]::IsNullOrWhiteSpace($Project)) {
    $devopsInfo = Get-DevOpsProjectFromFile
    if ($devopsInfo) {
        if ([string]::IsNullOrWhiteSpace($Organization) -and $devopsInfo.Organization) {
            $Organization = $devopsInfo.Organization
        }
        if ([string]::IsNullOrWhiteSpace($Project) -and $devopsInfo.Project) {
            $Project = $devopsInfo.Project
        }
    }
}

# Ask user to fill out required parameters
if ([string]::IsNullOrWhiteSpace($Organization)) {
    $Organization = Read-Host "Enter Azure DevOps Organization (e.g. https://dev.azure.com/your-org)"
    if ([string]::IsNullOrWhiteSpace($Organization)) {
        Write-Error "Organization parameter is required. Aborting."
        exit 1
    }
}
if ([string]::IsNullOrWhiteSpace($Project)) {
    $Project = Read-Host "Enter Azure DevOps Project Name"
    if ([string]::IsNullOrWhiteSpace($Project)) {
        Write-Error "Project parameter is required. Aborting."
        exit 1
    }
}

# Execute the function
Get-InProgressUserStories -org $Organization -proj $Project
