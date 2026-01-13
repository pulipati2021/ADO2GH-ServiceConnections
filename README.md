# Azure DevOps GitHub Pipeline Setup - Version 4.0

**Status**: ✅ Production Ready | **Date**: January 13, 2026

---

## Quick Start (2 Minutes)

### Run the Script
```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
```

### Follow the Menu
1. **Step 1**: Get PAT and List Projects
2. **Step 2**: Select Project and View Service Connections
3. **Step 3**: Configure Pipelines (Fill CSV)
4. **Step 4**: Validate Webhooks
5. **Exit**

**Total time**: ~10 minutes

---

## What This Does

### Validates Azure DevOps PAT
- Takes your Azure DevOps PAT
- Tests it works
- Lists all projects in your organization

### Lists Service Connections
- Shows all GitHub service connections in your project
- Auto-fills service connection name in CSV

### Configures Pipelines
- Collects GitHub organization/repo information
- Auto-fills project and service connection details
- Saves everything to `SERVICE-CONNECTIONS.csv`
- Allows multiple repos in one session

### Validates Webhooks
- Shows webhook URLs in GitHub
- Guides you to verify webhooks exist
- Logs verification results

---

## Prerequisites

✓ Azure DevOps PAT → Get from: https://dev.azure.com/[ORG]/_usersSettings/tokens  
✓ Azure DevOps Organization Name → e.g., `git-AzDo`  
✓ GitHub account with repo access  

---

## The 4 Steps Explained

### Step 1: Get PAT and List Projects (1 minute)

**What you provide:**
- Azure DevOps PAT
- Organization name

**What happens:**
- Script validates PAT works
- Lists all projects in organization
- Stores both for next steps

**Example output:**
```
✓ PAT validated!
Projects found: 3
  - Calamos-Test
  - MyOtherProject
  - Archive
```

### Step 2: Select Project and View Service Connections (1 minute)

**What you provide:**
- Project number (1, 2, or 3)

**What happens:**
- Script fetches service connections
- Lists all in selected project
- Stores service connection name for Step 3

**Example output:**
```
Selected: Calamos-Test
Service Connections:
  - github-oauth (Type: github)
  - github-alt (Type: github)
```

### Step 3: Configure Pipelines - Fill CSV (5 minutes)

**What you provide (for each pipeline):**
- Service connection number (pick from list)
- GitHub organization/owner
- GitHub repository name
- Pipeline name
- Pipeline YAML file (default: azure-pipelines.yml)

**What happens:**
- Script collects information
- Auto-fills: Organization, Project, Service Connection
- Saves to CSV file
- Allows adding multiple pipelines

**CSV format:**
```
Organization,ProjectName,ServiceConnectionName,RepositoryName,RepositoryOwner,PipelineFile,Status,Notes
git-AzDo,Calamos-Test,github-oauth,my-repo-1,my-org,azure-pipelines.yml,Pending,
```

### Step 4: Validate Webhooks (3 minutes)

**What you do:**
- Go to each GitHub repo webhook settings
- Verify webhook from Azure DevOps exists
- Check webhook shows 200 status

**Script does:**
- Lists GitHub webhook URLs for each repo
- Guides you to the right location
- Logs verification results

**What to check:**
```
GitHub: https://github.com/[OWNER]/[REPO]/settings/hooks
Look for: webhook from dev.azure.com
Status: 200 (successful)
```

---

## CSV File Format

### Columns
```
Organization          - Azure DevOps organization (auto-filled)
ProjectName          - Azure DevOps project (auto-filled)
ServiceConnectionName - GitHub service connection (auto-filled)
RepositoryName       - GitHub repo name (you provide)
RepositoryOwner      - GitHub org/owner (you provide)
PipelineFile         - YAML file name (you provide, default: azure-pipelines.yml)
Status               - Current status (auto-filled: Pending)
Notes                - Any notes (optional)
```

### Example
```
git-AzDo,Calamos-Test,github-oauth,AzureRepoCode-CalamosTest,im-sandbox-phanirb,azure-pipelines.yml,Pending,
git-AzDo,Calamos-Test,github-oauth,another-repo,im-sandbox-phanirb,azure-pipelines.yml,Pending,
```

---

## Files Included

### Main Script
**ServiceConnection-Helper.ps1** (260 lines)
- Clean, simple PowerShell script
- 4-step workflow
- Logging to file
- Error handling

### Configuration
**SERVICE-CONNECTIONS.csv**
- Auto-populated by Step 3
- Tracks all repositories and pipelines
- Ready for next phase

### Logs
**pipeline-setup.log** (created on first run)
- Every action logged with timestamp
- Useful for debugging
- Audit trail

---

## Error Handling

### "PAT not valid"
**Solution**: 
- Check PAT in https://dev.azure.com/[ORG]/_usersSettings/tokens
- Create new PAT if expired
- Try Step 1 again

### "No projects found"
**Solution**:
- Check organization name is correct
- Verify PAT has proper access
- Check user permissions in Azure DevOps

### "No service connections found"
**Solution**:
- Go to Azure DevOps Project Settings → Service Connections
- Create GitHub service connection manually (one-time)
- Run Step 2 again

### "Webhook not found in GitHub"
**Solution**:
- Service connection may need to be configured in pipeline settings
- Update pipeline YAML with GitHub trigger first
- Check GitHub repository settings

---

## Logging

All actions are logged to `pipeline-setup.log`:

```
[2026-01-13 14:30:00] Session started
[2026-01-13 14:30:05] PAT validated for org: git-AzDo
[2026-01-13 14:30:08] Found 3 projects in organization: git-AzDo
[2026-01-13 14:30:12] Found 2 service connections in project: Calamos-Test
[2026-01-13 14:30:18] Added pipeline: MyPipeline1 (my-org/my-repo-1)
[2026-01-13 14:30:25] Webhook verified: my-org/my-repo-1
[2026-01-13 14:30:48] Session ended
```

Use this to debug issues or audit actions.

---

## What's NOT Automated (On Purpose)

❌ **Service Connection Creation** - Create manually in Azure DevOps UI (one-time)  
❌ **Pipeline YAML Updates** - Update manually with GitHub trigger configuration  
❌ **Webhook Creation** - Azure DevOps creates automatically  
❌ **Pipeline Execution** - Test manually by pushing code  

**Why?** These require user review and browser interaction. They're better left manual.

---

## Next Steps (After v4.0)

Once you complete all 4 steps:

1. **Update Pipeline YAML** in your GitHub repository
   - Add GitHub trigger section
   - Reference the service connection

2. **Configure Pipeline Settings** in Azure DevOps
   - Set trigger source to GitHub
   - Select repository

3. **Test by Pushing Code**
   - Should trigger pipeline automatically
   - Verify in Azure DevOps

---

## Workflow Example

**Scenario**: Add 3 repositories to Calamos-Test project

```
STEP 1: Validate PAT
  Input: PAT + Organization name
  Output: Projects listed
  
STEP 2: Select Project
  Input: Project number (1)
  Output: Service connections listed
  
STEP 3: Add Repositories
  Input (first repo):
    - Service Connection: 1
    - GitHub Organization: my-org
    - GitHub Repository: my-repo-1
    - Pipeline Name: Pipeline1
    - YAML File: azure-pipelines.yml
  Output: Row added to CSV
  
  Input (second repo):
    - Service Connection: 1
    - GitHub Organization: my-org
    - GitHub Repository: my-repo-2
    - Pipeline Name: Pipeline2
    - YAML File: azure-pipelines.yml
  Output: Row added to CSV
  
  Input (third repo):
    - Service Connection: 1
    - GitHub Organization: my-org
    - GitHub Repository: my-repo-3
    - Pipeline Name: Pipeline3
    - YAML File: azure-pipelines.yml
  Output: Row added to CSV
  
STEP 4: Verify Webhooks
  Check: https://github.com/my-org/my-repo-1/settings/hooks
  ✓ Webhook verified
  
  Check: https://github.com/my-org/my-repo-2/settings/hooks
  ✓ Webhook verified
  
  Check: https://github.com/my-org/my-repo-3/settings/hooks
  ✓ Webhook verified

DONE: CSV ready, webhooks verified, logs created
```

---

## Timeline

| Step | Action | Time |
|------|--------|------|
| 1 | Validate PAT, List Projects | 1 min |
| 2 | Select Project, List Service Connections | 1 min |
| 3 | Configure Pipelines, Update CSV | 5 min |
| 4 | Validate Webhooks in GitHub | 3 min |
| **Total** | **Complete Setup** | **~10 min** |

---

## Features

✅ Simple 4-step workflow  
✅ Auto-fills CSV format  
✅ Validates Azure DevOps PAT  
✅ Lists projects and service connections  
✅ Guides webhook verification  
✅ Logs all actions  
✅ Clear error messages  
✅ Clean, readable code  
✅ Production ready  

---

## Support

### Check These First
1. **Logs**: Look in `pipeline-setup.log` for error messages
2. **PAT**: Verify PAT is valid and not expired
3. **Organization**: Confirm organization name is correct
4. **Service Connection**: Ensure it exists in Azure DevOps

### Common Commands
```powershell
# Run the script
.\ServiceConnection-Helper.ps1

# View logs
Get-Content pipeline-setup.log

# View CSV
Get-Content SERVICE-CONNECTIONS.csv

# Check GitHub webhooks
# Go to: https://github.com/[OWNER]/[REPO]/settings/hooks
```

---

## GitHub Repository

**Location**: https://github.com/pulipati2021/ADO2GH-ServiceConnections

**Latest Version**: 4.0

**Status**: ✅ Production Ready

---

## Version Info

| Version | Date | Status |
|---------|------|--------|
| 1.0 | Jan 10 | Archived |
| 2.0 | Jan 11-12 | Archived |
| 3.0 | Jan 13 AM | Archived |
| **4.0** | **Jan 13 PM** | **Current** |

---

## Summary

This is a simple, clean tool for setting up Azure DevOps pipelines with GitHub repositories.

**It does 4 things:**
1. Validates your Azure DevOps PAT
2. Lists projects and service connections
3. Collects GitHub repo information and saves to CSV
4. Guides webhook validation in GitHub

**Total time**: ~10 minutes

**Result**: CSV file ready for next phase of setup

---

## Ready?

```powershell
.\ServiceConnection-Helper.ps1
```

Follow the menu. Done in 10 minutes.

---

**Questions?** Check the logs: `pipeline-setup.log`

**Issues?** Verify PAT and organization name.

**Ready to start?** Run the script now.
