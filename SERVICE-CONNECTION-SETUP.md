# Service Connection Setup for GitHub EMU → Azure DevOps Migration

**Purpose:** Enable GitHub EMU code pushes to trigger Azure DevOps pipelines

---

## The Problem

You migrated some repos to GitHub EMU, but your pipelines are still in Azure DevOps. When code is pushed to GitHub EMU, nothing happens in Azure DevOps.

```
GitHub EMU (code)  →  [No Connection]  →  Azure DevOps (pipelines)
                           ❌
```

---

## The Solution

Service Connection = Secure bridge that:
- Stores GitHub EMU credentials (PAT) encrypted in Azure DevOps
- Sets up webhook from GitHub EMU → Azure DevOps
- Allows pipelines to read code from GitHub EMU and trigger on push

```
GitHub EMU (code)  →  [Service Connection]  →  Azure DevOps (pipelines)
   (push event)            (webhook)               (auto trigger)
                           ✅
```

---

## Setup Steps

### Step 1: Prepare PATs

**GitHub EMU PAT:**
1. Go to: `https://your-emu-server/settings/tokens`
2. Click "Generate new token (classic)"
3. Name: `azure-devops-connection`
4. Scopes: `repo`, `read:org`, `admin:org_hook`
5. Copy token (save securely)

**Azure DevOps PAT:**
1. Go to: `https://dev.azure.com/your-org/_usersSettings/tokens`
2. Click "New Token"
3. Name: `github-emu-setup`
4. Scopes: `Build (Read & Execute)`, `Code (Read & Write)`, `Service Connections (Read & Manage)`
5. Copy token (save securely)

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

