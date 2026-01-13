# Service Connection Setup Guide - Version 3.0

## Quick Overview

This guide walks you through the simplified v3.0 workflow for GitHub service connections.

**Process**: Manual OAuth Service Connection → Script Validates → Update Pipelines

---

## Table of Contents
1. [Step 1: Create Service Connection with OAuth](#step-1-create-service-connection-with-oauth)
2. [Step 2: Run Script Setup](#step-2-run-script-setup)
3. [Step 3: Validate Service Connection](#step-3-validate-service-connection)
4. [Step 4: Update Pipelines](#step-4-update-pipelines)
5. [Step 5: Test](#step-5-test)

---

## Prerequisites

✓ Azure DevOps organization access  
✓ GitHub account (with repository access)  
✓ Azure DevOps Project Administrator role  
✓ PowerShell 5.1+ installed  
✓ Azure DevOps PAT (get from https://dev.azure.com/[ORG]/_usersSettings/tokens)  

---

## Step 1: Create Service Connection with OAuth

This is a **one-time manual step**. You do this in Azure DevOps UI.

### Instructions:

1. **Go to Service Connections**
   - URL: `https://dev.azure.com/[ORG]/[PROJECT]/_settings/adminservices`

2. **Click "New Service Connection"**

3. **Select GitHub**

4. **Click "Authorize AzureDevOps"**
   - Browser opens for GitHub login
   - Log in with your GitHub account
   - Click "Authorize"

5. **Name Your Service Connection**
   - Suggested: `github-oauth`

6. **Save**

### Result:
✅ Service connection created with OAuth  

---

## Step 2: Run Script Setup

1. **Open PowerShell**
   ```powershell
   cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
   .\ServiceConnection-Helper.ps1
   ```

2. **Select Option 1: Setup**

3. **Confirm Service Connection**
   - Answer: `yes`

4. **Provide Azure DevOps PAT**
   - From: https://dev.azure.com/[ORG]/_usersSettings/tokens

### Result:
✅ Configuration validated  

---

## Step 3: Validate Service Connection

1. **Run Script Again**
   ```powershell
   .\ServiceConnection-Helper.ps1
   ```

2. **Select Option 2: Validate**

3. **Review Results**
   - Script lists all GitHub service connections
   - Confirm `github-oauth` appears

### Result:
✅ Service connection verified  

---

## Step 4: Update Pipelines

Add GitHub repository resource to your pipeline YAML:

```yaml
trigger:
  branches:
    include:
    - main

resources:
  repositories:
  - repository: github-oauth
    type: github
    name: im-sandbox-phanirb/AzureRepoCode-CalamosTest
    endpoint: github-oauth
    trigger: true
```

### Result:
✅ Pipeline configured  

---

## Step 5: Test

1. **Run Script Option 4: Test**

2. **Verify Webhook**
   - GitHub → Settings → Webhooks
   - Should see Azure DevOps webhook

3. **Test Push**
   ```bash
   git push origin main
   ```

4. **Confirm Pipeline Triggers**
   - Azure DevOps → Pipelines
   - Should see new run

### Result:
✅ Pipeline triggers automatically  

---

## Timeline

| Step | Time |
|------|------|
| Create Service Connection | 3-5 min |
| Run Setup | 1 min |
| Validate | 1 min |
| Update Pipeline | 3-5 min |
| Test | 5 min |
| **Total** | **15-20 min** |

---

## Troubleshooting

### Service Connection Not Found
- Check: https://dev.azure.com/[ORG]/[PROJECT]/_settings/adminservices
- Verify service connection named `github-oauth` exists
- Run: Option 2 (Validate)

### Pipeline Not Triggering
- Check GitHub Webhooks: Settings → Webhooks → Recent Deliveries
- Look for 200 OK responses
- Check Azure DevOps build logs

### PAT Validation Failed
- Verify PAT not expired: https://dev.azure.com/[ORG]/_usersSettings/tokens
- Create new PAT if needed
- Re-run Setup (Option 1)

---

**Version**: 3.0 (Manual OAuth + Script Validation)  
**Last Updated**: January 13, 2026  
**Status**: Production Ready
