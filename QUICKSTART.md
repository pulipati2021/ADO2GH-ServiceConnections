# Quick Start - Version 4.0

**Don't read all the docs. Just follow this.**

---

## In 3 Minutes

### 1. Start Script
```powershell
cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\INFOMAGNUS\Migrations\ADO2GH\service-connections-NoPipelineMigration'
.\ServiceConnection-Helper.ps1
```

### 2. Follow Menu

**[1] Step 1** → Enter PAT + Organization name  
**[2] Step 2** → Pick a project  
**[3] Step 3** → Add GitHub repos (can add multiple)  
**[4] Step 4** → Verify webhooks in GitHub  
**[5] Exit** → Done

---

## What You Need Before Starting

✓ Azure DevOps PAT → Get from: https://dev.azure.com/[ORG]/_usersSettings/tokens  
✓ Organization Name → e.g., `git-AzDo`  
✓ GitHub repo access → Need to verify webhooks  

---

## What Happens in Each Step

| Step | Provides | Gets | Does |
|------|----------|------|------|
| 1 | PAT, Org | Projects list | Validates |
| 2 | Project # | Service connections | Lists |
| 3 | Service conn, repos | CSV updates | Auto-fills |
| 4 | Nothing | Webhook validation | Logs |

---

## CSV Gets Auto-Filled

**You provide:**
- GitHub Organization (owner)
- GitHub Repository Name  
- Pipeline Name

**Script auto-fills:**
- Organization (from Step 1)
- ProjectName (from Step 2)
- ServiceConnectionName (from Step 3)

---

## Step 4: Webhook Check

For each repo in CSV:
1. Go to GitHub: `https://github.com/[OWNER]/[REPO]/settings/hooks`
2. Look for webhook from `dev.azure.com`
3. Click it → Recent Deliveries
4. Check for status `200`
5. Say `yes` when script asks

---

## Common Issues

**"No projects found"**
- Wrong organization name
- PAT doesn't have access

**"No service connections"**
- Need to create one manually in Azure DevOps first
- Go to: Project Settings → Service Connections → New

**"Webhook not found in GitHub"**
- Pipeline YAML needs to reference service connection
- Or pipeline settings need to trigger on GitHub

---

## Result

After Step 4:
✓ CSV file filled with all repos and pipelines  
✓ Webhooks verified in GitHub  
✓ Log file created with all actions  
✓ Ready for next steps  

---

## Next Steps (After v4.0)

1. Update pipeline YAML with GitHub trigger
2. Set service connection in pipeline  
3. Test by pushing code to GitHub
4. Verify pipeline runs

---

## Files

| File | Purpose |
|------|---------|
| SERVICE-CONNECTIONS.csv | Configuration (auto-updated) |
| pipeline-setup.log | Activity log |
| ServiceConnection-Helper.ps1 | The script |

---

## That's It!

Run the script and follow the menu.

Questions? Check `VERSION-4.0-RELEASE.md` or `REDESIGN-SUMMARY.md`

---

**Version**: 4.0  
**Time**: 3 minutes to complete
