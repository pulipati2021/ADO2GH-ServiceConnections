# Version 3.0 - Simplified Manual OAuth Approach

**Date**: January 13, 2026  
**Status**: Production Ready  

---

## What Changed (vs Version 2.0)

| Aspect | v2.0 | v3.0 |
|--------|------|------|
| **Service Connection Creation** | API-based (failed) | Manual UI (simple) |
| **OAuth** | Automatic attempt | Browser-based, user controls |
| **Menu Options** | 5 steps | 4 steps |
| **Complexity** | High | Low |
| **Workflow** | Mixed (auto + manual) | Sequential (clear) |
| **CSV Columns** | Service connection data | Repository & pipeline data |

---

## The New Workflow

### STEP 1: Manual OAuth Setup (User does once)
```
1. Go to: dev.azure.com/[ORG]/[PROJECT]/_settings/adminservices
2. Click "New Service Connection"
3. Select "GitHub"
4. Click "Authorize AzureDevOps"
5. Complete OAuth in browser (login + authorize)
6. Name service connection: "github-oauth" (or custom)
7. Save

Result: Service connection with OAuth established
```

### STEP 2: Fill CSV
```csv
Organization,ProjectName,ServiceConnectionName,RepositoryName,RepositoryOwner,PipelineFile,Status,Notes
git-AzDo,Calamos-Test,github-oauth,AzureRepoCode-CalamosTest,im-sandbox-phanirb,azure-pipelines.yml,OAuth Created,Manual OAuth service connection
```

### STEP 3: Run Script - 4 Menu Options

**Option 1: Setup**
- Provide Azure DevOps PAT
- Validate PAT works
- Load configuration from CSV

**Option 2: Validate**
- List GitHub service connections
- Verify OAuth service connection exists
- Show connection details

**Option 3: Update Pipeline YAML**
- Display YAML template with GitHub resources
- Guide user to add GitHub trigger
- Manual or automated options

**Option 4: Test**
- Verify webhook in GitHub
- Test pipeline trigger with code push
- Troubleshooting guide

### STEP 4: Test and Monitor
- Push code to GitHub
- Verify pipeline triggers
- Monitor webhook deliveries

---

## Why This Approach is Better

### Simpler
- One-time manual OAuth setup (clear, user sees what's happening)
- No complex API calls for OAuth
- Script just validates and updates pipelines

### More Reliable
- Azure DevOps UI handles OAuth (proven method)
- No API limitations blocking OAuth
- User controls authorization

### Clearer UX
- User understands each step
- No confusion about where OAuth happens
- Sequential, predictable workflow

### Fewer Errors
- No "endpoint parameter null" errors
- No API timeout issues
- No PAT expiration during creation

---

## CSV Format Changes

### Old Format (v2.0)
```csv
Organization,ProjectName,RepositoryName,RepositoryOwner,ServiceConnectionName,Status,Notes
git-AzDo,Calamos-Test,AzureRepoCode-CalamosTest,im-sandbox-phanirb,sc_oath,Created,OAuth-based service connection
```

### New Format (v3.0)
```csv
Organization,ProjectName,ServiceConnectionName,RepositoryName,RepositoryOwner,PipelineFile,Status,Notes
git-AzDo,Calamos-Test,github-oauth,AzureRepoCode-CalamosTest,im-sandbox-phanirb,azure-pipelines.yml,OAuth Created,Manual OAuth service connection
```

**Changes:**
- ServiceConnectionName moved earlier (already created)
- PipelineFile added (for YAML updates)
- Status changed to reflect OAuth already done
- Simpler, more focused on pipelines

---

## Required APIs

**All operations use READ + basic UPDATE APIs:**

✅ List Service Connections (GET)
```
GET /[ORG]/[PROJECT]/_apis/serviceendpoint/endpoints
```

✅ Get Organization Info (GET)
```
GET /[ORG]/_apis/projects
```

✅ No OAuth creation API needed (user does manually)

✅ Pipeline YAML updates (manual or UI-based)

---

## Menu Structure (Simplified)

```
Main Menu
├─ Option 1: Setup
│  ├─ Verify service connection created manually
│  ├─ Get Azure DevOps PAT
│  └─ Validate PAT
│
├─ Option 2: Validate Service Connection
│  ├─ List GitHub service connections
│  ├─ Display connection details
│  └─ Confirm OAuth connection exists
│
├─ Option 3: Update Pipeline YAML
│  ├─ Show YAML template
│  ├─ Provide repo/connection info
│  └─ Guide manual or UI-based update
│
├─ Option 4: Test
│  ├─ Verify webhook in GitHub
│  ├─ Test pipeline trigger
│  └─ Troubleshooting
│
└─ Option 5: Exit
```

---

## Success Indicators

After running all 4 steps:

✅ Service connection exists with OAuth in Azure DevOps  
✅ Pipeline YAML updated with GitHub repository resource  
✅ Webhook appears in GitHub repository settings  
✅ Webhook shows successful deliveries (200 OK)  
✅ Pipeline triggers automatically on GitHub push  

---

## Time Estimates

| Step | Time | What User Does |
|------|------|----------------|
| Manual Setup | 3-5 min | Create service connection in Azure DevOps UI |
| Fill CSV | 2 min | Edit CSV with repo and pipeline info |
| Run Script | 1 min | Provide PAT, validate |
| YAML Update | 3-5 min | Add GitHub resource to pipeline YAML |
| Test | 5 min | Push code, verify trigger |
| **Total** | **15-20 min** | **Full setup complete** |

---

## Key Benefits Over Previous Versions

### vs OAuth-only approach:
- ✅ Works (no API limitations)
- ✅ Simpler (no complex REST calls)
- ✅ Clear (OAuth happens visibly in browser)

### vs PAT-based approach:
- ✅ More secure (OAuth instead of static token)
- ✅ Better UX (clear browser flow)
- ✅ Auto-refresh (Azure DevOps manages tokens)
- ✅ Production-ready

### vs Manual-only approach:
- ✅ Some automation (pipeline updates)
- ✅ Validation (checks configuration)
- ✅ Guided process (step-by-step)

---

## Next Release Ideas

For Version 4.0:
- Automated YAML updates (read YAML, modify, commit)
- Pipeline discovery (list pipelines, let user select)
- Multiple repositories support (batch operations)
- Rollback functionality (restore previous YAML)
- Webhook verification tests

---

## Files Included

| File | Purpose |
|------|---------|
| ServiceConnection-Helper.ps1 | Main script v3.0 |
| SERVICE-CONNECTIONS.csv | Configuration (new format) |
| OLD/ServiceConnection-Helper-v2.0.ps1 | Previous version (backup) |
| OLD/ServiceConnection-Helper-OLD.ps1 | v1.0 (archive) |

---

## Migration from v2.0 to v3.0

If you were using v2.0:

1. **Delete the old service connection** (created with PAT)
   - Go to Azure DevOps → Service Connections
   - Delete any PAT-based GitHub connections

2. **Create new service connection with OAuth** (one time)
   - Follow Step 1 in the new script

3. **Update CSV format**
   - Copy values to new format
   - Add pipeline file name

4. **Run the new script**
   - Everything else works the same

---

## Status

**Version 3.0: PRODUCTION READY** ✅

- Tested with Azure DevOps API
- Clear workflow
- Simple and reliable
- Recommended for all new setups

**Old versions available in OLD/ folder:**
- v2.0: API-based (backup)
- v1.0: OAuth-only attempt (reference)

---

**Ready to use! Run the script and follow the 4 steps.**
