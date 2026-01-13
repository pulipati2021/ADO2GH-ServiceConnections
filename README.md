# Service Connection Setup - GitHub ↔ Azure DevOps

**Version 3.0**: Simplified manual OAuth service connection + automated pipeline validation.

Enable GitHub repositories to trigger Azure DevOps pipelines via secure OAuth service connections.

---

## NEW in Version 3.0

This is a **complete redesign** based on architectural insights:

**v2.0 Approach (Too Complex)**:
- Attempted API-based service connection creation with PAT
- Required GitHub PAT input
- Complex validation logic
- **Issue**: Still required manual OAuth in pipeline triggers

**v3.0 Approach (Simplified)**:
- **Step 1**: Create OAuth service connection manually in Azure DevOps UI (one time)
- **Step 2**: Run script to setup and validate configuration
- **Step 3**: Update pipelines to use the service connection
- **Step 4**: Test and verify webhook
- **Result**: Cleaner, simpler, more reliable!

---

## The 4-Step Workflow

```
STEP 1: Create Service Connection with OAuth (Manual - UI)
   └─→ Go to Azure DevOps → Service Connections
   └─→ Click "New GitHub" → Authorize with OAuth
   └─→ Done! (One time only)

STEP 2: Run Script Setup
   └─→ Provide Azure DevOps PAT
   └─→ Script validates configuration
   └─→ Ready to use

STEP 3: Update Pipelines
   └─→ Add GitHub resource to pipeline YAML
   └─→ Or use Azure DevOps UI trigger config
   └─→ Webhook automatically created

STEP 4: Test and Verify
   └─→ Verify webhook in GitHub
   └─→ Test by pushing code
```

---

## Files Included

| File | Purpose |
|------|---------|
| `ServiceConnection-Helper.ps1` | **NEW**: Interactive menu with 4 simplified steps |
| `SERVICE-CONNECTIONS.csv` | Configuration (organization, project, repository) |
| `PREREQUISITES.md` | **NEW**: Detailed permission and setup requirements |
| `SETUP-GUIDE.md` | **NEW**: Step-by-step implementation guide |
| `VERSION-2.0-RELEASE.md` | **NEW**: Complete release notes and workflow details |
| `OLD/` | Previous version (archived) |

---

## Prerequisites

**Critical - Must Have Before Starting:**

1. **GitHub Permissions**
   - Owner permission on GitHub Organization
   - Admin permission on GitHub Repository
   - [See PREREQUISITES.md for how to check/request](PREREQUISITES.md)

2. **Azure DevOps PAT**
   - Go to: `https://dev.azure.com/YOUR-ORG/_usersSettings/tokens`
   - Scopes: `Code (Read & Write)`, `Release (Read & Write)`, `Build (Read & Execute)`, `Endpoint (Read & Execute & Manage)`
   - [See PREREQUISITES.md for detailed instructions](PREREQUISITES.md)

3. **GitHub PAT** (for service connection)
   - Go to: `https://github.com/settings/tokens`
   - Scopes: `repo`, `admin:repo_hook`, `read:org`
   - [See PREREQUISITES.md for detailed instructions](PREREQUISITES.md)

---

## Quick Start (4 Steps)

### Run the Script

```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
```

### Step 1: Check Prerequisites & Read PAT
- **Select**: Option 1 from menu
- **Duration**: 2-3 minutes
- **What you do**:
  - Verify you have GitHub Owner + Admin permissions
  - Provide your Azure DevOps PAT
  - Script stores it for current session only

### Step 2: Create Service Connection with PAT
- **Select**: Option 2 from menu
- **Duration**: 30 seconds
- **What happens**:
  - Script uses Azure DevOps REST API
  - Creates service connection with GitHub credentials
  - Service connection appears in Azure DevOps UI
  - You provide GitHub PAT when prompted

### Step 3: Configure Pipeline Trigger with GitHub OAuth
- **Select**: Option 3 from menu
- **Duration**: 2-3 minutes (mostly browser steps)
- **Manual steps required**:
  1. Go to Azure DevOps pipeline
  2. Edit → Triggers tab
  3. Change source from "Azure Repos Git" to "GitHub"
  4. **Authorize OAuth** (browser popup)
  5. Select your GitHub repository
  6. Save pipeline
  - Webhook is **automatically created** during OAuth

### Step 4: Test and Verify Webhook
- **Select**: Option 4 from menu
- **Duration**: 5-10 minutes
- **What you do**:
  1. Check webhook in GitHub repository settings
  2. Test by pushing code to GitHub
  3. Verify pipeline triggers automatically
  - Script provides links and detailed instructions

---

## Configuration File

Edit `SERVICE-CONNECTIONS.csv` with your details:

```csv
Organization,ProjectName,RepositoryName,RepositoryOwner,ServiceConnectionName,Status,Notes
git-AzDo,Calamos-Test,AzureRepoCode-CalamosTest,im-sandbox-phanirb,sc_oath,Created,OAuth-based service connection
```

**Fields:**
- `Organization`: Your Azure DevOps organization name
- `ProjectName`: Your Azure DevOps project name
- `RepositoryName`: GitHub repository name
- `RepositoryOwner`: GitHub username or organization
- `ServiceConnectionName`: Name for this service connection in Azure DevOps
- `Status`: Current status (Created, Pending, Failed, etc.)
- `Notes`: Any additional notes

---

## Complete Documentation

For detailed information, see:
- **[PREREQUISITES.md](PREREQUISITES.md)** - Permission requirements and PAT setup
- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed step-by-step guide
- **[VERSION-2.0-RELEASE.md](VERSION-2.0-RELEASE.md)** - Complete release notes and changes

---

## Credential Security

- PATs are **stored in-memory only** during script execution
- They are **never saved** to files
- They are **cleared** when the script exits
- You **re-enter PATs** each time you run the script (by design)

---

## Why This Approach?

**Key Discovery from Testing**:
Azure DevOps REST API **cannot** create OAuth service connections. OAuth requires browser-based user interaction.

**Solution**:
1. Create service connection with **PAT** (REST API works great)
2. Add **OAuth** in pipeline trigger UI (browser-based, secure)
3. Webhook is automatically created during OAuth step
4. Result: Works perfectly!

---

## Success Indicators

After completing all 4 steps, you should see:
- [x] Service connection exists in Azure DevOps
- [x] Webhook appears in GitHub repository settings
- [x] Webhook shows successful deliveries (200 OK)
- [x] Pipeline triggers automatically when code is pushed
- [x] OAuth authentication completed in browser

---

## Next Steps After Success

1. **Monitor first few pipeline runs** after code pushes
2. **Check both repositories** for synchronization
3. **Document** which pipelines use GitHub triggers
4. **Rotate PATs** every 90 days (security best practice)

---

## Troubleshooting

**Webhook not created?**
- Go back to Step 3
- Re-authenticate OAuth in pipeline settings
- Click Save to trigger webhook creation
- Wait 5-10 seconds for webhook to appear

**Pipeline doesn't trigger?**
- Check webhook in GitHub "Recent Deliveries" tab
- Verify webhook shows 200 OK responses
- Check pipeline YAML has proper trigger configuration

**OAuth fails?**
- Verify you have Owner permission on GitHub Organization
- Verify you have Admin permission on GitHub Repository
- Clear GitHub cookies and try again

**More details**: See [PREREQUISITES.md](PREREQUISITES.md) troubleshooting section

**After creating the service connection**, you must configure your pipelines to use GitHub as the trigger source.

> **Problem:** Pipeline triggers show only `azuregit` (Azure Repos), not GitHub

**Solution: Use Option 6 (Automated) or Manual:**

### Automated (RECOMMENDED) - Option 6
The helper script can automatically update your pipeline YAML:
1. Navigate to your repository directory
2. Run: `.\ServiceConnection-Helper.ps1`
3. Select **Option 6: Update Pipeline YAML for GitHub Triggers**
4. Script will automatically:
   - Find your `azure-pipelines.yml` file
   - Add GitHub repository resource
   - Update service connection reference
   - Update checkout step to use GitHub
   - Ask for confirmation before making changes

### Manual Setup
See [PIPELINE-CONFIG-GITHUB.md](PIPELINE-CONFIG-GITHUB.md) for:
- How to manually update pipeline YAML
- How to configure via Azure DevOps UI
- How to verify pipelines trigger on GitHub push

**After updating:**
- Commit: `git add azure-pipelines.yml && git commit -m 'Update pipeline for GitHub triggers'`
- Push: `git push`
- Test by pushing code to verify pipeline triggers

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
- **Use this ONLY if** you already have a service connection created manually (outside this script)
- **DO NOT use** if you used Option 1 or 2 (webhooks already created)
- Finds your existing service connection automatically
- Creates GitHub webhook to the existing service connection
- Creates Service Hook subscription automatically
- Perfect for: Already have manual service connection, just missing webhooks
- **After this, still need Option 6 to update pipeline YAML**

### 6. Update Pipeline YAML for GitHub Triggers **[AUTOMATED]**
**Automatically configure pipelines to use GitHub repository as trigger source:**
- Reads your `azure-pipelines.yml` file
- Automatically adds GitHub repository resource
- Updates service connection reference
- Updates checkout step to use GitHub
- Perfect for: Fixing "azuregit only" pipeline trigger issue
- No manual YAML editing required - script does it all
- Asks for confirmation before making changes

### 7. View Service Connections
- Links to Azure DevOps service connections settings
- Links to service hooks page
- Multiple projects support - menu to select

### 8. View CSV Data
- Displays all configured service connections from CSV
- Formatted table view for easy review
- No authentication required

### 9. Manage Authentication
- Add/update GitHub PAT anytime (for Option 1 - PAT-based)
- Add/update Azure DevOps PAT anytime
- Clear individual or all PATs
- View current authentication status

### 10. Quick Setup Wizard (Guided Workflow) **[RECOMMENDED FOR NEW USERS]**
**Complete automated setup in the right sequence - prevents user mistakes:**
- Choose your preferred setup method (A, B, or C)
- Runs all required steps in the correct order automatically
- **No option to skip required steps**
- **No option to run conflicting operations**
- Guides you from service connection creation all the way to completed setup
- **Perfect for**: First-time users, teams, production setups

**Three Guided Paths:**

**Path A: PAT-Based Setup** (Quick ~2-3 minutes)
1. Creates service connection with GitHub PAT
2. Validates connection works
3. Updates pipeline YAML for GitHub triggers
4. Done! Shows final commit/push instructions

**Path B: OAuth Setup (RECOMMENDED)** (~3-4 minutes with browser step)
1. Creates service connection with OAuth (includes browser authorization)
2. Validates connection works
3. Updates pipeline YAML for GitHub triggers
4. Done! Shows final instructions (no token expiration worries!)

**Path C: Manual Service Connection** (for existing connections)
1. Creates webhooks for your already-created service connection
2. Validates connection works
3. Updates pipeline YAML for GitHub triggers
4. Done! Shows final instructions

**Why use the Wizard?**
- Prevents running Option 5 after Option 1/2 (which would be redundant)
- Ensures Option 6 (pipeline YAML) is never skipped
- Shows clear progress with "Step 1 Complete", "Step 2 Complete" messages
- Displays final checklist and commit instructions
- Can't accidentally skip important steps
- Ideal for teams where multiple people run the script

### 11. Exit
- Exit the helper script

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
