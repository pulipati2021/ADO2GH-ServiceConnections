# Manual vs Automated Tasks - Service Connection Setup

**Quick View:** What YOU do vs What SCRIPTS do

---

## 🛠️ MANUAL TASKS (You Must Do)

### Task 1: Create GitHub EMU PAT
**Why Manual:** Only GitHub EMU admin can create tokens  
**Time:** 2 minutes  
**Steps:**
1. Go to: `https://your-emu-server/settings/tokens`
2. Click "Generate new token (classic)"
3. Name: `azure-devops-connection`
4. Scopes: ✓ repo, ✓ read:org, ✓ admin:org_hook
5. Copy token (save somewhere safe)

**Output:** `ghp_xxxxxxxxxxxxxxxxx` (your GitHub EMU PAT)

---

### Task 2: Create Azure DevOps PAT
**Why Manual:** Only Azure DevOps user can create tokens  
**Time:** 2 minutes  
**Steps:**
1. Go to: `https://dev.azure.com/your-org/_usersSettings/tokens`
2. Click "New Token"
3. Name: `github-emu-setup`
4. Scopes: ✓ Build (Read & Execute), ✓ Code (Read & Write), ✓ Service Connections (Read & Manage)
5. Copy token (save somewhere safe)

**Output:** `[PAT string]` (your Azure DevOps PAT)

---

### Task 3: Connect Pipeline to GitHub EMU Repo
**Why Manual:** Pipeline configuration is unique per team  
**Time:** 3-5 minutes  
**Steps:**
1. Go to: `https://dev.azure.com/your-org/your-project/_build`
2. Select your pipeline → Click **Edit**
3. Under **Repository** section → Click **Modify connection**
4. Select service connection: `github-service-connection`
5. Select repository from GitHub EMU dropdown
6. Click **Save**

**Verification:**
- Pipeline now shows GitHub EMU repo
- Trigger settings should have webhook enabled

---

### Task 4: Test Pipeline Trigger
**Why Manual:** Only you can push real code to test  
**Time:** 5 minutes  
**Steps:**
1. Make a small commit to your GitHub EMU repo
2. Push to main/master branch
3. Wait 10 seconds
4. Check Azure DevOps pipeline (should show new run)
5. If triggered = ✅ Success

**Troubleshooting if not triggered:**
- Check GitHub EMU webhook: Settings → Webhooks → Look for Azure DevOps entry
- Check webhook delivery history for errors
- Verify pipeline trigger type is set to "Webhook"

---

### Task 5: Verify & Monitor GitHub Webhooks
**Why Manual:** You must verify webhooks are created and receiving events  
**Time:** 3-5 minutes  
**What Are Webhooks?** When you create a service connection, Azure DevOps automatically creates a webhook in your GitHub repo. This webhook sends push events to Azure DevOps to trigger your pipeline.

**Steps to Verify Webhook:**
1. Go to GitHub repo: `https://your-github-server/your-org/your-repo`
2. Click **Settings** → **Webhooks**
3. You should see an entry like: `https://dev.azure.com/your-org/_apis/public/repos/github/webhooks`
4. Click on it to expand details

**What to Check:**
- ✓ Webhook exists (means service connection was set up)
- ✓ Payload URL shows Azure DevOps endpoint
- ✓ Events set to: **Just the push event** (or **All events**)
- ✓ Delivery History shows recent successful deliveries (green checkmarks)

**Troubleshooting Webhook Issues:**
| Problem | Cause | Solution |
|---------|-------|----------|
| **No webhook exists** | Service connection not created | Run setup script again |
| **Red X in delivery** | 404 Not Found error | GitHub Enterprise Server selected instead of GitHub - DELETE service connection and recreate selecting "GitHub" type |
| **No deliveries** | Webhook disabled or no pushes | Push code to repo to trigger webhook |
| **Deliveries fail** | Network/auth issues | Check Azure DevOps PAT hasn't expired |

**How to Delete & Recreate:**
1. Go to GitHub Settings → Webhooks → Delete the webhook
2. Go to Azure DevOps Project Settings → Service connections → Delete service connection
3. Run setup script again (it will recreate both)

**Key Point:** If you see "404" errors in webhook delivery history, this means you selected **GitHub Enterprise Server** type instead of **GitHub** type when creating the service connection. This is a common mistake that must be fixed.

---

### Task 6: Handle PAT Renewal (Ongoing)
**Why Manual:** PATs expire (usually 90 days)  
**When:** Before PAT expiration date  
**Steps:**
1. Generate new GitHub PAT (Task 1)
2. Update in Azure DevOps: Project Settings → Service connections → Edit → Update token
3. Or regenerate service connection using setup script with new PAT

**Note:** If webhook deliveries start showing 401 errors after PAT expires, regenerate service connection with new PAT

---

## 🤖 AUTOMATED TASKS (Scripts Do)

### Task 1: Create Service Connection
**Script:** `setup-github-service-connection.ps1`  
**What It Does:**
- Takes your PATs as input
- Creates service connection in Azure DevOps project
- Encrypts and stores GitHub PAT in Azure DevOps vault
- Sets up webhook from GitHub EMU to Azure DevOps
- Tests if it works

**Command:**
```powershell
.\OLD\setup-github-service-connection.ps1 `
  -Organization "your-org" `
  -ProjectName "your-project" `
  -GitHubServerUrl "https://your-emu-server.com"
```

**What You Provide:**
- Organization name
- Project name  
- GitHub EMU server URL
- GitHub EMU PAT (when prompted)
- Azure DevOps PAT (when prompted)

**What It Creates:**
- Service connection in Azure DevOps
- Encrypted credential storage
- Webhook configuration

**Time:** 2-3 minutes

---

### Task 2: Validate Service Connection
**Script:** `validate-service-connection.ps1`  
**What It Does:**
- Checks if service connection exists
- Verifies it's accessible
- Confirms GitHub EMU connection works
- Reports status

**Command:**
```powershell
.\OLD\validate-service-connection.ps1 `
  -Organization "your-org" `
  -Project "your-project" `
  -ServiceConnectionName "github-service-connection"
```

**Output:**
```
OK - SUCCESS
  Service connection found and accessible
  Name: github-service-connection
  Type: github
  URL: https://your-emu-server.com
```

**Time:** 30 seconds

---

### Task 3: Validate GitHub PAT
**Script:** `validate-github-token.ps1`  
**What It Does:**
- Tests if GitHub EMU PAT is valid
- Checks token scopes
- Verifies organization access

**Command:**
```powershell
.\OLD\validate-github-token.ps1 `
  -GitHubToken "your-github-emu-pat" `
  -GitHubOrg "your-github-org"
```

**Output:**
```
OK - Token is VALID
  Logged in as: your-username
  Token scopes: OK
  Can access organization: your-org
```

**Time:** 30 seconds

---

### Task 4: List All Pipelines
**Script:** `list-all-pipelines.ps1`  
**What It Does:**
- Shows all pipelines in your project
- Helps you identify which ones need connecting

**Command:**
```powershell
.\OLD\list-all-pipelines.ps1
```

**Output:**
```
Found 2 Pipeline(s)
━━━━━━━━━━━━━━━━━━━
Pipeline ID:   1
Pipeline Name: DotNet-GHAS

Pipeline ID:   2
Pipeline Name: Migration-testing
```

**Time:** 30 seconds

---

## 📊 Comparison Table

| Task | Who/What | Time | Can Repeat? |
|------|----------|------|------------|
| **Create GitHub PAT** | Manual (You) | 2 min | Yes (new token each time) |
| **Create Azure DevOps PAT** | Manual (You) | 2 min | Yes (new token each time) |
| **Create Service Connection** | Automated (Script) | 2 min | Yes (overwrites existing) |
| **Validate Service Connection** | Automated (Script) | 30 sec | Yes (safe to run anytime) |
| **Verify GitHub Webhooks** | Manual (You) | 3 min | Yes (verify anytime) |
| **Troubleshoot Webhook Issues** | Manual (You) | 5-10 min | Yes (as needed) |
| **Connect Pipeline to Repo** | Manual (You) | 5 min | Yes (one per pipeline) |
| **Test Trigger** | Manual (You) | 5 min | Yes (sanity check) |

---

## ⏱️ Total Time Breakdown

| Phase | Task | Time | Manual? |
|-------|------|------|---------|
| **Setup** | GitHub PAT | 2 min | ✓ |
| | Azure DevOps PAT | 2 min | ✓ |
| | Run setup script | 2 min | ✗ (automated) |
| **Verify** | Verify GitHub webhooks | 3 min | ✓ |
| **Configure** | Connect pipeline to repo | 5 min | ✓ |
| **Test** | Push test code | 5 min | ✓ |
| | Verify trigger | 2 min | ✓ |
| **TOTAL** | | **21 minutes** | 9 manual + 1 automated |

---

## 🔄 Workflow Overview

```
MANUAL                          AUTOMATED                    MANUAL
┌──────────────┐               ┌──────────────┐            ┌──────────────┐
│ Create PATs  │── PATs────→   │ Setup Script │──Service──→│ Verify GitHub│
│ (5 min)      │              │ (2 min)      │  Connection │ Webhooks     │
└──────────────┘               └──────────────┘  + Webhook │ (3 min)      │
                                                           └──────────────┘
                                                                 ↓
                                                           MANUAL
                                                           ┌──────────────┐
                                                           │ Connect Pipe │
                                                           │ (5 min)      │
                                                           └──────────────┘
                                                                 ↓
                                                           MANUAL
                                                           ┌──────────────┐
                                                           │ Test Trigger │
                                                           │ (5 min)      │
                                                           └──────────────┘
```

---

## ✅ Checklist

**Manual - Create Tokens:**
- [ ] GitHub PAT created and copied
- [ ] Azure DevOps PAT created and copied

**Automated - Run Scripts:**
- [ ] Run setup script
- [ ] Service connection created successfully

**Manual - Verify:**
- [ ] GitHub webhook exists in repo Settings → Webhooks
- [ ] Webhook shows successful deliveries (green checkmarks)
- [ ] No 404 errors in webhook delivery history
- [ ] If 404 errors: Recreate service connection with "GitHub" type (not "GitHub Enterprise Server")

**Manual - Configure:**
- [ ] Pipeline connected to GitHub repo
- [ ] Trigger settings show webhook is enabled

**Manual - Test:**
- [ ] Pushed test code to GitHub
- [ ] Pipeline triggered automatically in Azure DevOps
- [ ] Pipeline ran successfully

---

## 🎯 Key Points

**Manual Tasks = Decisions & Authentication**
- Only you can create tokens (security)
- Only you know which pipeline connects to which repo (business logic)
- Only you can test with real code (testing)

**Automated Tasks = Repetitive Work**
- Scripts handle API calls to Azure DevOps
- Scripts handle webhook setup in GitHub EMU
- Scripts validate everything works
- Scripts can run multiple times safely

**Use Cases for Automation:**
- Multiple repos? Run script multiple times (one per repo)
- Multiple projects? Run script multiple times (one per project)
- Monitoring? Add script to Azure DevOps pipeline to validate health

---

## 💡 Pro Tips

1. **Save your PATs safely** - You'll need them if service connection breaks
2. **Use environment variables** - Set `$env:GH_PAT` and `$env:ADO_PAT` to skip token prompts
3. **Run validation regularly** - `validate-service-connection.ps1` is safe to run anytime
4. **Document your setup** - Keep note of which pipeline connects to which repo
5. **Test before production** - Use a test repo/pipeline first

