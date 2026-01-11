# Configuring Azure DevOps Pipelines to Trigger from GitHub

**Problem:** Pipeline triggers show only `azuregit`, not your GitHub repository

**Root Cause:** Pipeline is still configured to use Azure Repos as the source repository

---

## Solution: Update Pipeline to Use GitHub

### Option A: Via Pipeline YAML (Recommended)

Update your pipeline YAML file (usually `azure-pipelines.yml`):

```yaml
trigger:
  batch: true
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - src/**
      - tests/**

resources:
  repositories:
    - repository: GitHubRepo
      type: github
      endpoint: github-service-connection  # This MUST match your service connection name
      name: OWNER/REPO-NAME
      ref: refs/heads/main
```

**Key Points:**
- `endpoint`: Must match the service connection name created earlier (e.g., `github-service-connection`)
- `name`: Format is `OWNER/REPO-NAME` (e.g., `my-org/my-repo`)
- `type: github`: Tells Azure DevOps to use GitHub

### Option B: Via Azure DevOps UI (Visual Pipeline Editor)

**Step 1: Edit Pipeline**
1. Go to: `https://dev.azure.com/ORG/PROJECT/_build/pipelines/PIPELINE-ID`
2. Click **Edit**

**Step 2: Change Repository Source**
1. Click the three dots (...) at top right
2. Select **Triggers**
3. Under "Continuous integration"
4. Click **Repository** dropdown
5. Select your GitHub repository (should appear if service connection is set up)
6. Select **GitHub** branch to trigger on
7. Click **Save**

**Step 3: Verify Trigger Settings**
1. In the pipeline editor, look at the top
2. You should now see:
   - Repository: `OWNER/REPO-NAME` (GitHub)
   - Branch: `main` (or your branch)
   - Not showing `azuregit` anymore

---

## Checklist: Fixing "azuregit only" Problem

- [ ] Service connection created and working (Option 1 or 2 in helper script)
- [ ] Service connection is **GitHub type** (not GitHub Enterprise Server)
- [ ] Service connection authorized (if using OAuth)
- [ ] Pipeline YAML includes `resources.repositories` section with GitHub endpoint
- [ ] Service connection name in YAML matches actual service connection name
- [ ] Repository name format is correct: `OWNER/REPO-NAME`
- [ ] Pipeline triggers set to GitHub repository (not Azure Repos)
- [ ] Saved the pipeline

---

## Example: Complete Pipeline YAML

```yaml
trigger:
  batch: true
  branches:
    include:
      - main
  paths:
    include:
      - '**'

resources:
  repositories:
    - repository: GitHub
      type: github
      endpoint: github-service-connection
      name: my-org/my-repo
      ref: refs/heads/main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - checkout: GitHub
    clean: true
    fetchDepth: 0

  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'

  - script: |
      npm install
      npm run build
    displayName: 'Build'
```

---

## Why "azuregit" Still Shows

**Possible Causes:**

1. **Pipeline not updated from Azure Repos original**
   - Pipeline was created in Azure DevOps originally
   - Code was in Azure Repos, now moved to GitHub
   - Pipeline configuration wasn't updated

2. **Service connection not referenced in YAML**
   - YAML doesn't specify the GitHub service connection
   - Pipeline defaults to Azure Repos

3. **Trigger configuration still points to Azure Repos**
   - Pipeline UI settings still configured for Azure Repos
   - Need to change via UI triggers

---

## Troubleshooting

### "Endpoint not found" Error

**Error:** `Repository endpoint 'github-service-connection' not found`

**Solution:**
- Verify service connection name is correct
- Check spelling exactly matches
- Service connection must be in the same project as the pipeline
- If in different project: use `endpoint: ProjectName/github-service-connection`

### GitHub Repo Not Appearing in Dropdown

**Problem:** Can't see GitHub repo in repository selection

**Solution:**
1. Verify service connection is created and working
2. If OAuth: Complete authorization step
3. Try saving and refreshing the browser
4. Check service connection type is "github" (not "githubenterprise")
5. Manually type the repo name in YAML format: `OWNER/REPO-NAME`

### Still Not Triggering

**Check:**
1. Trigger is on the correct GitHub branch
2. Service hook subscription created (use helper script Option 2)
3. GitHub webhook exists in repository settings
4. Recent deliveries in GitHub webhook show success
5. Azure DevOps Service Hook subscription exists at: `ORG/PROJECT/_settings/serviceHooks`

---

## Quick Conversion Script

If you have multiple pipelines to migrate, this helps:

**For each pipeline:**
1. Get current trigger branch from pipeline settings
2. Update YAML with GitHub repository section (above)
3. Replace `trigger` branch name with GitHub branch
4. Test with a small code change
5. Verify trigger fires

---

## Next Steps

1. **Identify** which pipeline needs GitHub triggers
2. **Choose** Option A (YAML) or Option B (UI)
3. **Update** the pipeline configuration
4. **Test** by pushing code to GitHub
5. **Verify** pipeline runs automatically

**Need Help?**
- Check pipeline runs at: `ORG/PROJECT/_build/pipelines`
- Check GitHub webhooks at: `github.com/OWNER/REPO/settings/hooks`
- Check Azure Service Hooks at: `dev.azure.com/ORG/PROJECT/_settings/serviceHooks`
