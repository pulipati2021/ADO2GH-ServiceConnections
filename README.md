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
| `PIPELINE-CONFIG-GITHUB.md` | How to configure pipelines to use GitHub triggers |

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
1. **Prompt for PATs** (GitHub + Azure DevOps)
2. **Display interactive menu** with 7 options
3. All credentials stored in-memory only

### Step 3: Credentials & Security

- PATs are stored **in-memory only** for this session
- They are **never saved** to files
- They are **cleared** when the script exits
- You can update PATs anytime via Option 7

---

## Two Setup Workflows

### Workflow A: Full Automation (Option 1)
**If you don't have a service connection yet:**
- Use Option 1: "Create Service Connection from CSV"
- Creates service connection + webhook + service hook automatically
- Best for: Starting fresh

### Workflow B: Webhook-Only (Option 4)
**If you already created service connection manually (OAuth):**
- Already created service connection in Azure DevOps UI using OAuth
- Now need to create webhooks to trigger pipelines
- Use Option 4: "Create Webhook Only for Existing Service Connections"
- Script finds your service connection and adds webhooks
- Best for: Already have OAuth service connection, just missing webhooks

**Why choose Workflow B?**
- You manually created service connection with OAuth in Azure DevOps UI
- Need webhooks to trigger pipelines on code push
- Don't want to recreate service connection
- Option 4 handles this automatically

---

## Step 4: Configure Pipelines to Use GitHub Triggers

**After creating the service connection**, you must configure your pipelines to use GitHub as the trigger source.

> **Problem:** Pipeline triggers show only `azuregit` (Azure Repos), not GitHub

**Solution:** See [PIPELINE-CONFIG-GITHUB.md](PIPELINE-CONFIG-GITHUB.md) for:
- How to update pipeline YAML to use GitHub service connection
- How to configure pipeline triggers via Azure DevOps UI
- How to verify pipelines trigger on GitHub push

**Quick Summary:**
- Update `azure-pipelines.yml` to reference your service connection
- Set trigger repository to your GitHub repo
- Test by pushing code to GitHub
- Verify pipeline runs automatically

---

## Helper Script Menu Options

### 1. Create Service Connection (PAT-based)
**Use GitHub Personal Access Token for authentication:**
- Creates service connection via Azure DevOps REST API
- Stores GitHub PAT encrypted in Azure DevOps vault
- Creates GitHub webhook automatically  
- Creates Service Hook subscription automatically
- **Good for**: Quick setup, testing, automation scripts
- **Limitation**: Webhooks may fail if PAT expires or scopes change

### 2. Create Service Connection (OAuth-based) **[RECOMMENDED]**
**Use OAuth for more reliable authentication:**
- Creates service connection that uses GitHub OAuth flow
- **Azure DevOps handles token refresh automatically**
- More reliable webhook delivery (no PAT expiration issues)
- Creates Service Hook subscription automatically
- Requires manual OAuth authorization step in browser
- **Good for**: Production environments, long-term reliability
- **Advantage**: Webhooks work even if GitHub PAT expires

**Why choose OAuth over PAT?**
- OAuth tokens are managed by Azure DevOps automatically
- No PAT expiration causing webhook failures
- GitHub can revoke individual OAuth apps without affecting others
- More secure - no static token in Azure DevOps vault
- Webhooks have better reliability

### 3. Validate Service Connection
**Automatic validation with Azure CLI:**
- Runs validation automatically if Azure CLI installed
- Shows service connection details in table format
- **Detects type mismatches** - warns if GitHub Enterprise used for Cloud repos
- Multiple connections support - menu to select which to test
- Manual fallback command provided if Azure CLI not available

### 4. Test GitHub Webhook
- Instructions for verifying webhook in GitHub
- Multiple repositories support - menu to select
- Direct links to GitHub webhook settings page

### 5. Create Webhook Only (for Existing Service Connections)
**Setup webhooks without creating service connection:**
- **Use this if you already created service connection manually via OAuth**
- Finds your existing service connection automatically
- Creates GitHub webhook to the existing service connection
- Creates Service Hook subscription automatically
- Perfect for: Already have OAuth service connection, just missing webhooks

### 6. View Service Connections
- Links to Azure DevOps service connections settings
- Links to service hooks page
- Multiple projects support - menu to select

### 7. View CSV Data
- Displays all configured service connections from CSV
- Formatted table view for easy review
- No authentication required

### 8. Manage Authentication
- Add/update GitHub PAT anytime (for Option 1 - PAT-based)
- Add/update Azure DevOps PAT anytime
- Clear individual or all PATs
- View current authentication status

---

## Authentication & Security

### PAT vs OAuth Comparison

| Feature | PAT (Option 1) | OAuth (Option 2) |
|---------|---|---|
| **Setup Complexity** | Simple | Requires browser authorization |
| **Webhook Reliability** | Can fail if PAT expires | Always works - Azure DevOps refreshes tokens |
| **Token Expiration** | Yes - PAT must be regenerated every 90 days | No - Azure DevOps manages token refresh |
| **GitHub Interaction** | Webhooks use static PAT token | Webhooks use OAuth flow |
| **Best For** | Quick testing, development | Production, long-term reliability |
| **Failure Risk** | Higher - PAT expiration causes 401 errors | Lower - Azure DevOps handles refresh |

**The Problem with PAT Webhooks:**
- GitHub webhook delivery fails when GitHub PAT expires
- Shows error: "Last delivery was not successful. Invalid HTTP Response: 401"
- Must manually regenerate PAT and update service connection
- Not suitable for hands-off production environments

**The Solution with OAuth:**
- Azure DevOps automatically refreshes OAuth tokens
- Webhooks continue working indefinitely
- No manual intervention needed
- Recommended for production use

### How PATs Are Handled

✓ **Secure (Option 1 only):**
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

1. **For Production**: Use Option 2 (OAuth) - more reliable
2. **For Testing**: Use Option 1 (PAT) - simpler setup
3. **If using PAT**: Set expiration dates and rotate every 90 days
4. **Scopes**: Only grant necessary permissions

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

### Webhook Returns 401 Error

**Root Cause:** PAT (Personal Access Token) has expired

**Symptoms:**
- Webhook created but shows 401 (Unauthorized) errors
- "Last delivery was not successful. Invalid HTTP Response: 401"
- Webhooks worked before but now fail

**Why This Happens:**
- Option 1 (PAT-based) stores a GitHub PAT in the service connection
- GitHub PATs expire (usually 90 days)
- When PAT expires, webhook deliveries fail with 401 errors

**Fix:**
1. **Recommended**: Use Option 2 (OAuth) instead - no expiration issues
2. **Quick Fix**: Regenerate GitHub PAT and update service connection
   - Create new GitHub PAT
   - Go to Azure DevOps Project Settings > Service Connections
   - Edit the service connection
   - Update the PAT with the new one

---

### Webhook Returns 404 Error

**Root Cause:** Wrong service connection type selected

**Symptoms:**
- Webhook created but shows 404 errors
- "Last delivery was not successful. Invalid HTTP Response: 404"
- Service Hook created but doesn't trigger pipelines

**Most Common Mistake:**
- Selected "GitHub Enterprise Server" for GitHub Cloud repositories
- This causes Azure DevOps to generate a webhook URL that GitHub doesn't recognize

**The Script Now Detects This:**
- After creation, validates service connection type
- Shows warning if type is not 'github'
- Validation tool (Option 3) also checks type

**Fix:**
1. Delete the incorrect service connection
2. Create new one selecting **'GitHub'** (NOT 'GitHub Enterprise Server')
3. Re-run script to create webhook and service hook

---

### Service Connection Creation Failed

**Check:**
1. Azure DevOps PAT has correct scopes:
   - Build (Read & Execute)
   - Code (Read & Write)
   - Service Connections (Read & Manage)
2. PAT is not expired
3. You have access to project settings
4. Repository owner name is correct
5. Project name exists in Azure DevOps

### Service Hook Not Triggering Pipelines

**Check:**
1. Service Hook subscription was created successfully
2. Pipeline configured to use GitHub as source repository
3. Branch filters match your push branches
4. Review Service Hooks at: `https://dev.azure.com/ORG/PROJECT/_settings/serviceHooks`

---

### OAuth Service Connection Not Working

**If using Option 2 (OAuth):**

1. **Complete OAuth Authorization**
   - Service connection created but needs authorization
   - Go to: `https://dev.azure.com/ORG/PROJECT/_settings/adminservices`
   - Click on your service connection
   - Click "Authorize" button
   - GitHub will ask for permission - click "Authorize"
   - You'll be redirected back to Azure DevOps

2. **After Authorization**
   - Webhooks will start working automatically
   - Service Hook will trigger pipelines on code push
   - No PAT expiration issues

### Multiple Connections - Selection Issues

**The Script Now:**
- Displays menu when multiple connections exist
- Lets you select which one to create/validate/test
- Includes "Cancel" option to go back without action

### Azure CLI Commands Not Working

**Install Azure CLI:**
```powershell
choco install azure-cli
# or
winget install Microsoft.AzureCLI
```

**Configure:**
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
