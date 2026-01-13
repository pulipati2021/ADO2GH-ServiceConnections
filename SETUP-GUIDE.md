# Service Connection Setup Guide - Step by Step

## Quick Overview

This guide walks you through setting up a GitHub service connection for your Azure DevOps pipeline using the new simplified process.

**Process**: PAT-based Service Connection + Manual GitHub OAuth in Pipeline Trigger

---

## Table of Contents
1. [Prerequisites Check](#1-prerequisites-check)
2. [Create Service Connection](#2-create-service-connection-with-pat)
3. [Configure Pipeline Trigger](#3-configure-pipeline-trigger-with-oauth)
4. [Test and Verify](#4-test-and-verify)

---

## 1. Prerequisites Check

### Before You Start:
✓ Read PREREQUISITES.md completely  
✓ Have both PATs ready (Azure DevOps + GitHub)  
✓ Verify GitHub permissions (Owner + Admin)  
✓ Have repository information ready  

### Run Step 1 of Script:
```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
# Select: [1] Check Prerequisites & Read PAT
```

**What Happens**:
- Script displays GitHub permission requirements
- You verify you have Owner + Admin permissions
- Script asks for Azure DevOps PAT
- PAT is stored for current session

**If Issues**:
- If permissions not verified: Stop and request them (see PREREQUISITES.md)
- If no PAT available: Get one from https://dev.azure.com/[ORG]/_usersSettings/tokens

---

## 2. Create Service Connection with PAT

### What is a Service Connection?
A service connection is Azure DevOps' way to securely store credentials for external systems (GitHub, Docker, etc.).

### Run Step 2:
```powershell
# In the menu (from Step 1)
# Select: [2] Create Service Connection with PAT
```

**What the Script Does**:
1. Uses your Azure DevOps PAT to authenticate
2. Creates a GitHub service connection via REST API
3. Stores GitHub PAT securely in Azure DevOps
4. Names it as configured in SERVICE-CONNECTIONS.csv

**What You Provide**:
- GitHub Personal Access Token (when prompted)

**Expected Output**:
```
✓ Service connection created successfully!
  ID: [connection-id]
```

**If Errors**:
- "endpoint parameter null" → GitHub PAT is missing or invalid
- "parameters collection empty" → Azure DevOps PAT issues
- Check PREREQUISITES.md for PAT scope requirements

### Important Note:
Service connection is created with PAT. OAuth will be added in Step 3 via pipeline trigger.

---

## 3. Configure Pipeline Trigger with GitHub OAuth

### What is OAuth?
OAuth is a secure way to authorize Azure DevOps to access GitHub **without storing credentials**. It happens through your browser.

### Key Insight:
**OAuth is configured in the Pipeline Trigger settings, NOT in service connection creation.**

This is the crucial difference from traditional approaches!

### Run Step 3:
```powershell
# In the menu
# Select: [3] Configure Pipeline Trigger (GitHub OAuth)
```

**What the Script Does**:
- Displays detailed manual instructions
- Shows you exactly where to go in Azure DevOps UI
- Explains what to click and what to authorize

**Manual Steps You'll Perform**:

#### Step 3a: Go to Pipeline Settings
1. Navigate to: `https://dev.azure.com/[ORG]/[PROJECT]/_build`
2. Find your pipeline
3. Click "Edit" button

#### Step 3b: Configure Trigger Source
1. Click "Triggers" tab
2. Look for source repository selection
3. Click dropdown (currently shows "Azure Repos Git")
4. Select "GitHub"

#### Step 3c: Authenticate with OAuth
1. **OAuth dialog appears** in browser
2. You'll be asked to authorize Azure DevOps access
3. Click "Authorize AzureDevOps" (or similar)
4. **IMPORTANT**: This requires Owner permission on your GitHub Organization

#### Step 3d: Select Repository
1. After OAuth succeeds, GitHub repositories appear
2. Select: `[OWNER]/[REPO]` (from your configuration)
3. Click "Save"

#### Step 3e: What Happens Automatically
✓ Azure DevOps creates webhook in GitHub automatically  
✓ Webhook is configured to trigger on "push" by default  
✓ You can modify trigger events (PR, issues, etc.) if needed  

**Expected Result**:
- Pipeline trigger now set to GitHub
- Webhook exists in your GitHub repository
- OAuth is established and active

**Webhook Verification**:
You can see the webhook in GitHub:
- Go to: `https://github.com/[OWNER]/[REPO]/settings/hooks`
- You should see a webhook from "api.github.com" or "azure.com"
- Click it to see delivery history

---

## 4. Test and Verify

### Run Step 4:
```powershell
# In the menu
# Select: [4] Test and Verify Webhook
```

**What the Script Does**:
- Shows you where to find webhook in GitHub
- Explains how to test by making a code change
- Provides troubleshooting guide if needed

### Manual Test Steps:

#### Test 1: Verify Webhook Exists
```powershell
# In GitHub:
# 1. Go to repository settings → Webhooks
# 2. Look for webhook from Azure DevOps
# 3. Click on it
# 4. Click "Recent Deliveries"
# 5. You should see successful deliveries (200 OK)
```

#### Test 2: Trigger Pipeline with Code Push
```powershell
# Clone or navigate to your repository
cd your-repo

# Make a small change
echo "# test" >> README.md

# Commit and push
git add .
git commit -m "test pipeline trigger"
git push

# Check if pipeline runs:
# 1. Go to Azure DevOps pipeline: https://dev.azure.com/[ORG]/[PROJECT]/_build
# 2. Look for new run
# 3. Should start within 1-2 minutes of push
```

#### Test 3: Verify Pipeline Success
- Pipeline should complete successfully
- Check pipeline output for GitHub-specific messages
- Verify code changes are reflected in both repos

### What Success Looks Like:
```
✓ Webhook exists in GitHub repository settings
✓ Recent deliveries show 200 OK responses
✓ Pipeline runs automatically when code is pushed
✓ Pipeline completes without OAuth errors
✓ Both repositories stay in sync
```

### Troubleshooting Test Failures:

**Problem**: Webhook not appearing in GitHub
- **Solution**: 
  - Go back to Step 3
  - Re-authenticate OAuth
  - Click Save again on pipeline settings
  - Wait 5-10 seconds for webhook to appear

**Problem**: Webhook exists but shows errors
- **Solution**:
  - Click webhook in GitHub
  - Click "Recent Deliveries"
  - Click on failed delivery
  - Check error message for details
  - Common: "No pipeline matches the run request" → Check pipeline YAML

**Problem**: Pipeline doesn't trigger on push
- **Solution**:
  - Verify webhook is enabled (green checkmark in GitHub)
  - Check pipeline YAML has `trigger: auto` or proper branch config
  - Wait 2-3 minutes for delivery to process
  - Look in "Recent Deliveries" to verify GitHub sent the event

---

## Complete Workflow Summary

```
START
  │
  ├─→ Step 1: Check Prerequisites & Read PAT
  │   └─→ Verify GitHub permissions
  │   └─→ Provide Azure DevOps PAT
  │
  ├─→ Step 2: Create Service Connection with PAT
  │   └─→ Provide GitHub PAT
  │   └─→ Service connection created in Azure DevOps
  │
  ├─→ Step 3: Configure Pipeline Trigger with OAuth
  │   └─→ Manual browser-based OAuth authorization
  │   └─→ Select GitHub as trigger source
  │   └─→ Webhook automatically created by Azure DevOps
  │
  ├─→ Step 4: Test and Verify
  │   └─→ Verify webhook in GitHub settings
  │   └─→ Test by pushing code
  │   └─→ Confirm pipeline triggers automatically
  │
  └─→ SUCCESS: GitHub → Azure DevOps pipeline integration working
```

---

## Important Notes

### GitHub Permissions
- OAuth will FAIL if you don't have Owner permission on Organization
- Webhook creation will FAIL if you don't have Admin permission on Repository
- These are non-negotiable for the OAuth process

### OAuth Authentication
- OAuth only happens once during pipeline trigger configuration
- Subsequent pushes to GitHub trigger webhook, NOT OAuth dialog
- If OAuth expires, re-authenticate in pipeline settings

### Security
- Service connection stores GitHub PAT securely
- OAuth token is session-based (expires, auto-refreshed)
- Both tokens should be rotated periodically (90-day recommendation)

### Synchronization
- **Azure DevOps → GitHub**: Pipeline code changes auto-sync
- **GitHub → Azure DevOps**: Webhook triggers pipeline (one-way)
- Both repositories can have different branch structures

---

## Next Steps After Success

Once verification complete:

1. **Update Pipeline YAML** (if needed):
   - Modify `trigger:` section for specific branches
   - Add `pr:` section for pull request triggers
   - Configure build options

2. **Configure Branch Policies** (GitHub):
   - Require CI/CD to pass before merging
   - Require code review
   - Protect main branch

3. **Monitor First Runs**:
   - Watch several pipeline runs after code pushes
   - Check for any OAuth or webhook errors
   - Verify synchronization between repositories

4. **Document Your Setup**:
   - Record which pipeline uses GitHub trigger
   - Document any custom trigger events configured
   - Note service connection name for team reference

---

## Support & Troubleshooting

For more detailed troubleshooting:
- See PREREQUISITES.md → Troubleshooting section
- Check pipeline logs in Azure DevOps
- Verify webhook deliveries in GitHub settings
- Check Recent Deliveries for error messages

---

**Last Updated**: January 12, 2026  
**Version**: 2.0 (PAT-based with GitHub OAuth)  
**Status**: Production Ready
