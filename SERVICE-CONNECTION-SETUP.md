# Service Connection Setup - Version 3.0

**Purpose:** Enable GitHub code pushes to trigger Azure DevOps pipelines via OAuth

---

## The Problem

You have code in GitHub, but your pipelines are in Azure DevOps. When code is pushed to GitHub, nothing happens in Azure DevOps.

```
GitHub (code)  →  [No Connection]  →  Azure DevOps (pipelines)
   (push)                ❌
```

---

## The Solution

Service Connection with OAuth = Secure bridge that:
- Authorizes Azure DevOps to access your GitHub repository
- Sets up webhook from GitHub → Azure DevOps
- Allows pipelines to trigger automatically on push

```
GitHub (code)  →  [OAuth Service Connection]  →  Azure DevOps (pipelines)
   (push event)        (webhook trigger)            (auto run)
                            ✅
```

---

## Why OAuth?

✅ **Secure**: No static PAT stored  
✅ **User-Controlled**: OAuth happens in browser with your approval  
✅ **Auto-Refresh**: Tokens refresh automatically  
✅ **Audit Trail**: GitHub logs all authorized access  
✅ **Simple**: One-time browser authorization  

---

## Setup Steps

### Step 1: Create Service Connection with OAuth (Azure DevOps UI)

**This is a one-time manual step. You do this in your browser.**

1. Go to Azure DevOps:
   ```
   https://dev.azure.com/[ORG]/[PROJECT]/_settings/adminservices
   ```

2. Click "New Service Connection"

3. Select "GitHub"

4. Click "Authorize AzureDevOps"
   - Browser opens GitHub login
   - You log in with your GitHub account
   - You click "Authorize"
   - Browser returns to Azure DevOps
   - Shows: "Successfully created GitHub service connection"

5. Name the service connection: `github-oauth`

6. Click "Save"

**Result**: ✅ Service connection created with OAuth

---

### Step 2: Prepare Azure DevOps PAT

1. Go to: `https://dev.azure.com/[ORG]/_usersSettings/tokens`
2. Click "New Token"
3. Name: `github-pipeline-setup`
4. Scopes: `Code (Read & Write)`, `Build (Read & Execute)`
5. Copy token (you'll provide this to the script)

---

### Step 3: Run Script Setup

```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
```

Select: `[1] Setup`

When prompted:
- "Is your service connection created with OAuth?" → Answer: `yes`
- "Azure DevOps PAT" → Paste the PAT from Step 2

**Result**: ✅ Script validates configuration

---

### Step 4: Run Script Validate

Still in the menu, select: `[2] Validate`

Script will:
- List all GitHub service connections
- Confirm your `github-oauth` service connection exists
- Show connection details

**Result**: ✅ Service connection verified in Azure DevOps

---

### Step 5: Update Pipeline YAML

Edit your pipeline YAML file (`azure-pipelines.yml`) to add GitHub trigger:

```yaml
trigger:
  branches:
    include:
    - main

resources:
  repositories:
  - repository: github-oauth
    type: github
    name: [OWNER]/[REPO]
    endpoint: github-oauth
    trigger: true
```

Commit and push to GitHub.

**Result**: ✅ Pipeline configured for GitHub webhook trigger

---

### Step 6: Run Script Test

In the menu, select: `[4] Test`

Script will guide you to:
- Check webhook in GitHub settings
- Test by pushing code
- Verify pipeline triggers

**Result**: ✅ Pipeline triggers automatically on GitHub push

---

## Success Indicators

After setup complete:

✅ Service connection `github-oauth` appears in Azure DevOps  
✅ Webhook appears in GitHub repository settings  
✅ Webhook shows 200 OK responses in "Recent Deliveries"  
✅ Pipeline triggers automatically when code is pushed  
✅ Build completes successfully  

---

## Troubleshooting

### Service Connection Creation Failed
- OAuth requires Owner permission on GitHub organization
- Go to GitHub: Settings → Applications → Authorized OAuth Apps
- Check that "AzureDevOps" is authorized
- Try creating service connection again

### OAuth Popup Didn't Appear
- Browser popup blocker might be blocking it
- Disable popup blocker for Azure DevOps
- Clear browser cookies
- Try again

### Webhook Not Appearing in GitHub
- Go back to Step 5, edit pipeline YAML again
- Save and wait 10 seconds
- Check GitHub Settings → Webhooks again

### Pipeline Not Triggering
- Check webhook "Recent Deliveries" shows 200 OK
- Verify pipeline YAML `trigger: true` is set
- Check that you pushed to the configured branch (default: main)
- Wait 2-3 minutes after push

---

## Key Differences from PAT-Based Approach

| Aspect | v2.0 (PAT) | v3.0 (OAuth) |
|--------|-----------|---------|
| Service Connection Creation | API (complex) | UI (simple) |
| Credentials Stored | GitHub PAT | OAuth token |
| Token Refresh | Manual | Automatic |
| Security | Good | Better |
| User Interaction | Minimal | OAuth browser |
| Webhook Setup | Manual | Automatic |

---

## Security Best Practices

1. **GitHub OAuth Credentials**
   - Stored securely in Azure DevOps
   - Never exposed in scripts
   - Auto-refresh by Azure DevOps

2. **Azure DevOps PAT**
   - Scoped to minimal permissions needed
   - Rotated every 90 days
   - Kept secure (never commit to repo)

3. **Webhook Security**
   - GitHub validates webhook signatures
   - Deliveries logged in GitHub settings
   - Only triggers on configured branches

---

## Next Steps

After service connection works:

1. Configure branch policies in GitHub
2. Add PR triggers in pipeline YAML (`pr: [main]`)
3. Monitor first few pipeline runs
4. Add additional pipelines using same service connection

---

**Version**: 3.0 (OAuth-based)  
**Last Updated**: January 13, 2026  
**Status**: Production Ready

---

### Step 2: Run Setup Script

```powershell
cd "c:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration"

.\OLD\setup-github-service-connection.ps1 `
  -Organization "your-ado-org" `
  -ProjectName "your-ado-project" `
  -GitHubServerUrl "https://your-emu-server.com"
```

**What happens:**
1. Script prompts for GitHub EMU PAT → Paste it
2. Script prompts for Azure DevOps PAT → Paste it
3. Script creates service connection in your Azure DevOps project
4. Credentials encrypted and stored in Azure DevOps vault
5. Webhook automatically configured in GitHub EMU

---

### Step 3: Validate Connection Works

```powershell
.\OLD\validate-service-connection.ps1 `
  -Organization "your-ado-org" `
  -Project "your-ado-project" `
  -ServiceConnectionName "github-service-connection"
```

**Expected output:**
```
OK - SUCCESS
  Service connection found and accessible
  Name: github-service-connection
  Type: github
  URL: https://your-emu-server.com
```

---

### Step 4: Connect Pipeline to GitHub EMU Repo

1. Go to: `https://dev.azure.com/your-ado-org/your-ado-project/_build`
2. Click pipeline to edit
3. Under **Repository**:
   - Click "Modify connection"
   - Select service connection: `github-service-connection`
   - Select repository from GitHub EMU
4. Click **Save**

---

### Step 5: Test Trigger

1. Push code to GitHub EMU repo
2. Wait 10 seconds
3. Check Azure DevOps pipeline → Should show new run triggered
4. If triggered = ✅ Working

---

## Troubleshooting

### Service Connection Not Found
- Run validate script to check it was created
- Go to Project Settings → Service connections
- Look for `github-service-connection`

### GitHub PAT Invalid
- Check PAT scopes: `repo`, `read:org`, `admin:org_hook`
- PAT must not be expired
- Generate new PAT from: `https://your-emu-server/settings/tokens`

### Pipeline Not Triggering
- Verify service connection is connected to pipeline (Step 4)
- Check webhook in GitHub EMU: Repository → Settings → Webhooks
- Look for Azure DevOps webhook and check delivery history
- Verify webhook is sending events on `push`

### Connection Says "Ready" But Can't Access Repo
- Verify GitHub EMU PAT has `repo` scope
- Verify user who created PAT has access to the repo
- Verify repository path is correct

---

## Files Reference

| File | Use Case |
|------|----------|
| `setup-github-service-connection.ps1` | Create service connection (Step 2) |
| `validate-service-connection.ps1` | Test it works (Step 3) |
| `validate-github-token.ps1` | Test GitHub PAT separately |
| `list-all-pipelines.ps1` | List pipelines in project |

---

## For Multiple EMU Repos

If you have multiple GitHub EMU repos in same project:
- Create ONE service connection (Steps 1-3)
- Connect multiple pipelines to same service connection (Step 4)
- One connection, multiple repos = clean setup

If repos are in different projects:
- Repeat Steps 1-3 for each project
- Each project needs its own service connection

---

## Key Points for EMU Migration

| Aspect | Detail |
|--------|--------|
| **GitHub EMU URL** | Use your EMU server URL (not github.com) |
| **Service Connection Type** | Still "GitHub" type, works for EMU |
| **Webhook** | Automatically set up by script |
| **Credentials** | Encrypted in Azure DevOps vault |
| **PAT Expiration** | Plan for PAT renewal (usually 90 days) |

---

## Done When:
✅ Service connection created and validated  
✅ Pipeline connected to GitHub EMU repo  
✅ Code push to GitHub EMU triggers pipeline in Azure DevOps

