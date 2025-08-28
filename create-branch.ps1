# Azure DevOps PowerShell Script using Azure CLI
# Lists user stories assigned to the current user with state "In Progress"

param(
    [Parameter(Mandatory=$true)]
    [string]$Organization,

    [Parameter(Mandatory=$true)]
    [string]$Project
)

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
AND [System.State] != 'Open'
AND [System.State] != 'Done'
AND [System.State] != 'Removed'
AND [System.State] != 'Rejected'
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
        Write-Host ""
        Write-Host "$($queryResult.Count) user stories assigned to $currentUser" -ForegroundColor Green

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
        $selectedLine = Read-Host "Select User Story"
        if ($selectedLine -match '^[0-9]+$' -and $selectedLine -ge 1 -and $selectedLine -le $workItems.Count) {
            $selectedItem = $workItems[$selectedLine - 1]

            # map type, if is not bug, write feature/
            if ($workItemType -ne "Bug") {
                $workItemType = "feature"
            }
            $title
            $branchName = "$($workItemType.ToLower())/$($id)-$($title.ToLower().Replace(' ', '-'))"
            # cut branch name after 100 chars
            $branchName = $branchName.Substring(0, [Math]::Min($branchName.Length, 100))
            $confirmation = Read-Host "$branchName (enter to confirm)"

            if (-not [string]::IsNullOrWhiteSpace($confirmation)) {
                $branchName = $confirmation
            }

            git checkout -b $branchName

        } else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Failed to query work items: $($_.Exception.Message)"
        return
    }
}

# Main execution
Write-Host "Azure DevOps User Story Query Script (using Azure CLI)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Validate parameters
if ([string]::IsNullOrWhiteSpace($Organization)) {
    Write-Error "Organization parameter is required"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Project)) {
    Write-Error "Project parameter is required"
    exit 1
}

# Execute the function
Get-InProgressUserStories -org $Organization -proj $Project
