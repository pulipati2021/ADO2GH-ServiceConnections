# Service Connection Setup - GitHub ↔ Azure DevOps

Enable GitHub repositories to trigger Azure DevOps pipelines via secure service connections.

---

## Purpose

After migrating code to GitHub (regular or EMU), your Azure DevOps pipelines still reside in ADO. This solution creates a **secure bridge** (service connection) that:

- Stores GitHub credentials encrypted in Azure DevOps
- Automatically creates webhooks to trigger pipelines on code push
- Allows pipelines to pull code from GitHub repositories

```
GitHub (code push)  →  [Service Connection]  →  Azure DevOps (pipelines trigger)
```

---

## Files Included

| File | Purpose |
|------|---------|
| `SERVICE-CONNECTIONS.csv` | Configuration file for repositories |
| `ServiceConnection-Helper.ps1` | Interactive menu helper script |
| `SERVICE-CONNECTION-SETUP.md` | Detailed setup documentation |
| `MANUAL-VS-AUTOMATED.md` | Comparison of manual vs automated approaches |

---

## Prerequisites

Before running the helper script, you need:

1. **GitHub PAT** (Personal Access Token)
   - Go to: `https://github.com/settings/tokens` (or your GitHub EMU instance)
   - Scopes: `repo`, `read:org`, `admin:org_hook`

2. **Azure DevOps PAT**
   - Go to: `https://dev.azure.com/YOUR-ORG/_usersSettings/tokens`
   - Scopes: `Build (Read & Execute)`, `Code (Read & Write)`, `Service Connections (Read & Manage)`

3. **Access to:**
   - GitHub repository settings (to verify webhooks)
   - Azure DevOps project settings (to create service connections)

---

## Quick Start

### Step 1: Configure Service Connection Details

Edit `SERVICE-CONNECTIONS.csv` with your details:

```csv
Organization,ProjectName,RepositoryName,RepositoryOwner,ServiceConnectionName,Status,Notes
git-AzDo,Calamos-Test,AzureRepoCode-CalamosTest,im-sandbox-phanirb,github-service-connection,Pending,
```

**Fields:**
- `Organization`: Your Azure DevOps organization name
- `ProjectName`: Your Azure DevOps project name
- `RepositoryName`: GitHub repository name
- `RepositoryOwner`: GitHub username or organization
- `ServiceConnectionName`: Name for this service connection in Azure DevOps
- `Status`: Current status (Pending, Created, Failed, etc.)
- `Notes`: Any additional notes

### Step 2: Run Helper Script

```powershell
.\ServiceConnection-Helper.ps1
```

The script will:
1. Ask if you want to provide PATs now
2. Display an interactive menu with options to:
   - Create service connections
   - Validate existing connections
   - Test webhooks
   - View configuration

### Step 3: Provide Credentials When Prompted

- PATs are stored **in-memory only** for this session
- They are **never saved** to files
- They are **cleared** when the script exits

---

## Helper Script Menu Options

### 1. Create Service Connection
- Requires: GitHub PAT + Azure DevOps PAT
- Provides step-by-step instructions for Azure DevOps UI
- You'll use the provided PATs in the Azure DevOps UI

### 2. Validate Service Connection
- Requires: Azure DevOps PAT (via Azure CLI)
- Verifies the connection exists in your project
- Provides test command to run

### 3. Test GitHub Webhook
- Requires: GitHub PAT (optional)
- Shows where to check webhook deliveries
- Helps verify webhook was created correctly

### 4. View Service Connections
- Opens direct links to Azure DevOps project settings
- Shows command to list connections via Azure CLI

### 5. View CSV Data
- Displays current configuration from CSV
- No authentication required

### 6. Manage Authentication
- Add new PATs anytime
- Clear specific PATs
- View current auth status

---

## Authentication & Security

### How PATs Are Handled

✓ **Secure:**
- Entered via masked password prompts
- Stored in PowerShell session memory only
- Never logged or displayed on screen
- Cleared when script exits

✗ **NOT Stored:**
- Not in CSV files
- Not in configuration files
- Not in logs
- Not on disk

### Best Practices

1. **Generate temporary PATs** - Set expiration dates
2. **Use minimal scopes** - Only grant necessary permissions
3. **Regenerate regularly** - Rotate credentials every 90 days
4. **Never commit PATs** - They're not stored here, but watch all files

---

## CSV Format Reference

```csv
Organization,ProjectName,RepositoryName,RepositoryOwner,ServiceConnectionName,Status,Notes
git-AzDo,MyProject,my-repo,my-org,github-conn-1,Pending,First service connection
git-AzDo,OtherProject,other-repo,my-org,github-conn-2,Created,Already configured
```

**Notes:**
- Do NOT add PAT columns to CSV
- Do NOT add full GitHub URLs to CSV
- Keep CSV in version control (safe - no secrets)

---

## Troubleshooting

### Service Connection Creation Failed

**Check:**
1. Azure DevOps PAT has correct scopes
2. PAT is not expired
3. You have access to project settings
4. Repository owner name is correct

### Webhook Not Created

**Check:**
1. GitHub PAT has `admin:org_hook` scope
2. Service connection was successfully created
3. GitHub repository is accessible with provided PAT
4. Check GitHub repository → Settings → Webhooks

### Azure CLI Commands Not Working

**Install Azure CLI:**
```powershell
choco install azure-cli
# or
winget install Microsoft.AzureCLI
```

**Login:**
```powershell
az login
az devops configure --defaults organization=https://dev.azure.com/YOUR-ORG
```

---

## Manual vs Automated

For detailed comparison between manual setup (Azure DevOps UI) vs automated (script), see `MANUAL-VS-AUTOMATED.md`.

---

## Support

For detailed setup instructions, see `SERVICE-CONNECTION-SETUP.md`.

For issues with Azure DevOps service connections, refer to [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops).
