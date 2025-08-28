# Azure DevOps Create-Branch

**Azure DevOps Create-Branch** is the only tool you'll ever need to switch branches.

- Automatically create branches with a common branch scheme
- Find assigned User Stories in DevOps and switch to the branch
- Branch exists? No problem, it'll switch to it
- You make an update to the user story? No worries, it will create a new branch for you

![Screenshot](Create-DevOps-Branch.png)

## Features

- **Lists user stories assigned to the current user** in Azure DevOps with states that are not closed, done, or otherwise completed.
- **Interactive selection**: Prompts you to select a user story from the list.
- **Automatic branch naming**: Creates a branch name in the format `feature/<id>-<title>` or `bug/<id>-<title>`.
- **Branch management**: Checks if the branch exists; if not, creates it. If it exists, the script now prompts you to choose whether to switch to the existing branch or create a new branch with "-2" appended to the name. Stashes/pops any open changes when switching.
- **Configurable behavior**: Option to always create a new branch or just check out if it exists (via `$AlwaysCreateBranch`).
- **Handles Azure CLI and extension setup**: Checks for Azure CLI and Azure DevOps extension, installs if missing.

## Branch Naming Scheme

Branches are automatically named using the following format:

```TYPE/ID-TITLE```

### Types

- `feature`
- `bug`

### Examples

- `feature/123-add-login-button`
- `feature/456-update-user-profile`
- `bug/789-fix-crash-on-save`
- `feature/1011-refactor-auth-module`

## Prerequisites

- **Azure CLI** installed and available in your PATH.
- **Git** installed.
- You must be logged in to Azure CLI (`az login`).

## Get Started


To run the script, open a PowerShell terminal and use one of the following commands:

```powershell
# Run, to get asked by parameters or read them from .devops-project file
.\create-branch.ps1

# With parameters
.\create-branch.ps1 MyOrganization MyProject

# With parameter names
.\create-branch.ps1 -Organization MyOrganization -Project MyProject

```

The script will guide you through selecting a user story and creating or switching branches automatically.

### Parameters

When you run the script, it determines the `Organization` and `Project` parameters using the following fallback order:

1. **Command-line parameters**: If you provide parameters directly to the script, these are used.
2. **.devops-project file**: If parameters are missing, the script searches for a `.devops-project` file in:
  - The current working directory
  - Each parent directory up to the git project root (if available)
  - As a final fallback, the folder containing the script itself
   The first `.devops-project` file found is used. You may include just one or both lines (`organization=...` and/or `project=...`).
3. **Interactive prompt**: If either parameter is still missing, the script will prompt you to enter the value interactively.

This ensures you can run the script from any subfolder in your project, and it will find your settings automatically if configured.

### Using a .devops-project file

You can create a `.devops-project` file in your current working directory (where you run the script) to avoid entering parameters each time. Example:

```text
organization=MyOrganization
project=MyProject
```

If you run the script without parameters, it will use any values found in this file. You may include just one or both lines; the script will prompt for any missing information.

## Notes

- The script only lists work items assigned to the current Azure AD user and in a non-completed state.
- Branch names are truncated to 100 characters for compatibility.
- If you have uncommitted changes, the script will stash them before switching branches and pop them after checkout.
- If the branch already exists, you can choose to switch to it or create a new branch with "-2" appended (e.g., `feature/123-title-2`).
- You can set `$AlwaysCreateBranch = $true` in the script to always create a new branch, even if it already exists.

## macOS Pro Tip

add this to your `.bash_prfile` or `.zshrc` file:

```bash
function createbranch(){
  pwsh PATHTOSCRIPT/create-branch.ps1 "YOURORGANIZATION" "YOURPROJECT"
}
alias branch=createbranch
alias b=createbranch
```

That way you can simply run `b` to create or switch branches.

## Troubleshooting

- If you see errors about Azure CLI or extensions, ensure both are installed and you are logged in.
- Make sure you run the script from a directory that is a valid Git repository.

## License

See `LICENSE` for details.
