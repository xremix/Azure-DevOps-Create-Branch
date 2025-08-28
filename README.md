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

- feature
- bug

### Examples

- `feature/123-add-login-button`
- `feature/456-update-user-profile`
- `bug/789-fix-crash-on-save`
- `feature/1011-refactor-auth-module`


## Prerequisites

- **Azure CLI** installed and available in your PATH.
- **Git** installed.
- You must be logged in to Azure CLI (`az login`).

## How to Run

1. Open a PowerShell terminal.
2. Run the script with the required parameters:

    ```powershell
    .\create-branch.ps1 -Organization <your-organization> -Project <your-project>
    ```

    - Replace `<your-organization>` with your Azure DevOps organization name.
    - Replace `<your-project>` with your Azure DevOps project name.

3. The script will:
   - Check your Azure CLI login and extension status.
   - List all user stories assigned to you that are in progress.
   - Prompt you to select a user story by number.
   - Suggest a branch name and allow you to confirm or edit it.
   - Create or check out the branch in your local Git repository.
  - If the branch already exists, you will be prompted to either switch to it or create a new branch with "-2" appended to the suggested name.

## Example

Parameters with names

```powershell
.\create-branch.ps1 -Organization MyOrganization -Project MyProject
```

Parameters in order

```powershell
.\create-branch.ps1 MyOrganization MyProject
```

No parameters

```powershell
.\create-branch.ps1
```

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
