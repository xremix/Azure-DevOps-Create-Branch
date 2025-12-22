# Get remote URL from git
$remoteUrl = git remote get-url origin

# Extract organization, project, and repo from remote URL
# Example: https://dev.azure.com/{organization}/{project}/_git/{repo}
# or: https://{username}@dev.azure.com/{organization}/{project}/_git/{repo}
if ($remoteUrl -match "https://(?:[^@]+@)?dev.azure.com/(?<org>[^/]+)/(?<proj>[^/]+)/_git/(?<repo>[^/]+)") {
    $organization = $matches['org']
    $project = $matches['proj']
    $repo = $matches['repo']
} else {
    Write-Error "Could not parse Azure DevOps remote URL. Found: $remoteUrl"
    exit 1
}

# Get current branch (source)
$sourceBranch = git rev-parse --abbrev-ref HEAD

# Target branch (default to 'develop')
$targetBranch = "develop"

# Construct Azure DevOps PR creation URL
# Project and repo names are already URL-encoded in the git remote URL
$prUrl = "https://dev.azure.com/$organization/$project/_git/$repo/pullrequestcreate?sourceRef=$sourceBranch&targetRef=$targetBranch"

Write-Host "Opening PR creation page in browser..."
Write-Host "Source: $sourceBranch -> Target: $targetBranch"

# Open URL in default browser
Start-Process $prUrl
