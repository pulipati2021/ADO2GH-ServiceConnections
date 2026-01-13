# Version 4.0 - Clean Simplified Workflow

**Date**: January 13, 2026  
**Status**: Production Ready

---

## What's Different (vs v3.0)

| Aspect | v3.0 | v4.0 |
|--------|------|------|
| **Complexity** | Multiple docs | Single script |
| **Menu** | 5 options | 4 steps |
| **Code** | 400+ lines | 260 lines |
| **Focus** | Confusing mix | Clear workflow |
| **User Experience** | Complex | Simple |

---

## The 4-Step Workflow

```
STEP 1: Get PAT and List Projects
  └─ Provide PAT
  └─ View all projects in organization

STEP 2: Select Project and View Service Connections
  └─ Pick a project
  └─ See all service connections in that project

STEP 3: Configure Pipelines (Fill CSV)
  └─ Select a service connection
  └─ Add GitHub repos and pipeline names
  └─ CSV auto-populates

STEP 4: Validate Webhooks in GitHub
  └─ Go to each GitHub repo
  └─ Check for webhook from Azure DevOps
  └─ Verify it's working (200 OK)
```

---

## How to Use

**Start the script:**
```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
```

**Menu appears:**
```
===== Azure DevOps GitHub Pipeline Setup v4.0 =====

  [1] Step 1: Get PAT and List Projects
  [2] Step 2: Select Project and View Service Connections
  [3] Step 3: Configure Pipelines (Fill CSV)
  [4] Step 4: Validate Webhooks
  [5] Exit
```

**Follow the steps in order:**

1. **Step 1**: Enter Azure DevOps PAT, org name → See all projects
2. **Step 2**: Pick a project → See service connections
3. **Step 3**: Pick a service connection → Fill in GitHub repos → CSV updates
4. **Step 4**: Verify webhooks exist in GitHub

---

## What Each Step Does

### Step 1: Validate and List Projects
- Takes Azure DevOps PAT
- Takes Organization name
- Validates PAT is correct
- Shows all projects in organization
- Stores PAT for next steps

### Step 2: Select Project and List Service Connections
- Shows projects (from Step 1)
- You pick one
- Shows all service connections in that project
- Service connection name is auto-filled in Step 3

### Step 3: Configure Pipelines - Fill CSV
- Shows available service connections
- You pick one
- Enter GitHub organization/owner
- Enter GitHub repository name
- Enter pipeline name
- Enter YAML file (or default: azure-pipelines.yml)
- Can add multiple pipelines
- CSV file updates automatically

### Step 4: Validate Webhooks
- Reads CSV file
- For each repository, shows webhook URL in GitHub
- You go to GitHub and verify webhook exists
- Logs results

---

## CSV Format

**Columns:**
```
Organization,ProjectName,ServiceConnectionName,RepositoryName,RepositoryOwner,PipelineFile,Status,Notes
```

**Example:**
```
git-AzDo,Calamos-Test,github-oauth,AzureRepoCode-CalamosTest,im-sandbox-phanirb,azure-pipelines.yml,Pending,Ready
```

**Auto-filled by script:**
- Organization (from Step 1)
- ProjectName (from Step 2)
- ServiceConnectionName (from Step 3)

**You provide:**
- RepositoryName (GitHub repo name)
- RepositoryOwner (GitHub org/owner)
- PipelineFile (YAML file name)

---

## Logging

All actions are logged to `pipeline-setup.log`:

```
[2026-01-13 14:30:00] Session started
[2026-01-13 14:30:05] PAT validated for org: git-AzDo
[2026-01-13 14:30:08] Found 3 projects in organization: git-AzDo
[2026-01-13 14:30:12] Found 2 service connections in project: Calamos-Test
[2026-01-13 14:30:18] Added pipeline: my-pipeline (my-org/my-repo)
[2026-01-13 14:30:25] Webhook verified: my-org/my-repo
```

---

## Error Handling

**"PAT not valid"**
- Check PAT in https://dev.azure.com/[ORG]/_usersSettings/tokens
- Create new PAT if expired
- Try Step 1 again

**"No projects found"**
- Check organization name
- Verify PAT has project access
- Check user permissions

**"No service connections found"**
- Go to Azure DevOps → Project → Settings → Service Connections
- Create a service connection first
- Run Step 2 again

**"CSV file not found"**
- Run Step 3 first to create CSV
- Then run Step 4 to validate

---

## Why This Version is Simpler

✅ **No confusion** - Step 1, 2, 3, 4 in order  
✅ **Auto-fills** - Project, service connection names auto-filled  
✅ **Focused** - Each step does one thing  
✅ **Clear** - Simple questions, clear feedback  
✅ **Logged** - All actions logged for audit  
✅ **Less code** - 260 lines vs 400+ in v3.0  

---

## Timeline

| Step | Time | What Happens |
|------|------|--------------|
| 1 | 1 min | Validate PAT, show projects |
| 2 | 1 min | Pick project, show service connections |
| 3 | 5 min | Add pipelines to CSV |
| 4 | 5 min | Verify webhooks in GitHub |
| **Total** | **12 min** | **All set!** |

---

## Next: Actual Pipeline Updates

After Step 4 completes, you need to:

1. Update pipeline YAML in GitHub repos with GitHub trigger
2. Set service connection in pipeline settings
3. Test by pushing code

*Future version may automate this*

---

**Version**: 4.0  
**Last Updated**: January 13, 2026  
**Status**: Production Ready - Ready to Use!
