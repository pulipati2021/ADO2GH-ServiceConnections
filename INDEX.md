# Getting Started - Complete Index

**Welcome to Azure DevOps ↔ GitHub Service Connection Migration - Version 2.0**

This document helps you navigate all available documentation and understand the complete process.

---

## Start Here (3 Documents)

### 1. [README.md](README.md) - Quick Overview (5 min read)
**What**: High-level overview of the new 4-step process  
**Best for**: Understanding what this does and the basic workflow  
**Contains**:
- Version 2.0 what's new
- 4-step overview
- Files included
- Prerequisites summary
- Quick start instructions
- Success indicators

### 2. [PREREQUISITES.md](PREREQUISITES.md) - Required Setup (10-15 min read)
**What**: Detailed requirements for GitHub permissions and PATs  
**Best for**: Before you run the script - verify you have everything needed  
**Contains**:
- GitHub permission requirements (Owner + Admin)
- How to check permissions
- How to request permissions
- How to create Azure DevOps PAT
- How to create GitHub PAT
- Pre-flight checklist
- Troubleshooting permission issues

### 3. [SETUP-GUIDE.md](SETUP-GUIDE.md) - Step-by-Step Instructions (20-30 min read)
**What**: Detailed walkthrough of each of the 4 steps  
**Best for**: Following along while using the script  
**Contains**:
- What each step does
- Expected outputs
- Exact commands to run
- Browser steps for OAuth
- Testing procedures
- Troubleshooting for each step
- Success indicators

---

## Reference Documents

### [VERSION-2.0-RELEASE.md](VERSION-2.0-RELEASE.md) - What Changed
**What**: Complete release notes for Version 2.0  
**Best for**: Understanding why we did this redesign  
**Contains**:
- Comparison of old vs new approach
- Why OAuth had to move to pipeline triggers
- Key insights from testing
- Complete 4-step workflow
- Files and their purposes
- Known limitations
- Success indicators

### [DEPLOYMENT-READY.md](DEPLOYMENT-READY.md) - Verification Checklist
**What**: Complete summary that system is ready  
**Best for**: Confirming everything is in place  
**Contains**:
- What was done
- Verification checklist
- File status
- Git commit history
- Usage instructions
- Troubleshooting guide
- Deployment readiness status

---

## Configuration Files

### [SERVICE-CONNECTIONS.csv](SERVICE-CONNECTIONS.csv) - Your Configuration
```csv
Organization,ProjectName,RepositoryName,RepositoryOwner,ServiceConnectionName,Status,Notes
git-AzDo,Calamos-Test,AzureRepoCode-CalamosTest,im-sandbox-phanirb,sc_oath,Created,OAuth-based service connection
```

**Edit this if**:
- Different organization
- Different project
- Different repository
- Different service connection name

---

## The Script: ServiceConnection-Helper.ps1

**Main script with 4 menu options**

```powershell
.\ServiceConnection-Helper.ps1
```

**Menu Options**:
1. Check Prerequisites & Read PAT
2. Create Service Connection with PAT
3. Configure Pipeline Trigger (GitHub OAuth)
4. Test and Verify Webhook
5. Exit

**Total Time**: ~15-20 minutes for complete setup

---

## Recommended Reading Order

For first-time users:

1. **This document** (you're reading it now!) - 2 min
2. **[README.md](README.md)** - Understand what we're doing - 5 min
3. **[PREREQUISITES.md](PREREQUISITES.md)** - Verify you have requirements - 10 min
4. **Run the script** - Execute the 4 steps - 15 min
5. **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Reference while running script - As needed

---

## Decision Tree

### "I need to set up a service connection"
→ Start with [README.md](README.md), then follow [SETUP-GUIDE.md](SETUP-GUIDE.md)

### "I don't have GitHub permissions"
→ Read [PREREQUISITES.md](PREREQUISITES.md) section "GitHub Permissions"

### "I don't know how to create a PAT"
→ Read [PREREQUISITES.md](PREREQUISITES.md) section "Azure DevOps PAT" and "GitHub PAT"

### "The script failed, what do I do?"
→ Check [SETUP-GUIDE.md](SETUP-GUIDE.md) troubleshooting for your step

### "What changed from Version 1.0?"
→ Read [VERSION-2.0-RELEASE.md](VERSION-2.0-RELEASE.md)

### "Is everything ready to use?"
→ Check [DEPLOYMENT-READY.md](DEPLOYMENT-READY.md)

### "I just want the quick version"
→ Jump to [README.md](README.md) "Quick Start" section

---

## Quick Facts

| Item | Details |
|------|---------|
| **Script** | ServiceConnection-Helper.ps1 |
| **Configuration** | SERVICE-CONNECTIONS.csv |
| **Total Setup Time** | 15-20 minutes |
| **Menu Options** | 4 clear steps |
| **Status** | Production Ready |
| **Tested** | Yes |
| **Documentation** | Complete |

---

## The 4-Step Process (Overview)

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Check Prerequisites (2-3 min)                          │
│ - Verify GitHub permissions                                    │
│ - Provide Azure DevOps PAT                                     │
└─────────────────────────────────────────────────────────────────┘
                           ⬇
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Create Service Connection (30 sec)                     │
│ - Create with Azure DevOps PAT (REST API)                      │
│ - Store GitHub credentials                                     │
└─────────────────────────────────────────────────────────────────┘
                           ⬇
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Configure Pipeline Trigger (2-3 min)                   │
│ - Edit pipeline in Azure DevOps                                │
│ - Change trigger to GitHub                                     │
│ - Authorize with OAuth (browser)                               │
│ - Webhook automatically created                                │
└─────────────────────────────────────────────────────────────────┘
                           ⬇
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Test and Verify (5-10 min)                             │
│ - Verify webhook in GitHub                                     │
│ - Test with code push                                          │
│ - Confirm pipeline triggers                                    │
└─────────────────────────────────────────────────────────────────┘
                           ⬇
                      SUCCESS! ✅
```

---

## Key Insights

### 1. OAuth Happens in Pipeline UI
Not during service connection creation. Azure DevOps API cannot automate OAuth.

### 2. Webhooks Are Automatic
When you complete OAuth in pipeline trigger, Azure DevOps automatically creates the webhook.

### 3. Simple 4-Step Process
- Create service connection (API)
- Configure trigger (browser)
- Test (manual)
- Done!

---

## Get Help

### Before Starting
→ [PREREQUISITES.md](PREREQUISITES.md)

### During Setup
→ [SETUP-GUIDE.md](SETUP-GUIDE.md)

### Troubleshooting
→ Each document has troubleshooting section

### Quick Reference
→ [README.md](README.md) Quick Start section

---

## Files in This Repository

```
📁 service-connections-NoPipelineMigration
├─ 📄 ServiceConnection-Helper.ps1 (340 lines) [MAIN SCRIPT]
├─ 📄 SERVICE-CONNECTIONS.csv [CONFIGURATION]
├─ 📄 README.md [OVERVIEW]
├─ 📄 PREREQUISITES.md [SETUP REQUIREMENTS]
├─ 📄 SETUP-GUIDE.md [STEP-BY-STEP]
├─ 📄 VERSION-2.0-RELEASE.md [RELEASE NOTES]
├─ 📄 DEPLOYMENT-READY.md [VERIFICATION]
├─ 📄 INDEX.md [THIS FILE]
├─ 📁 OLD/ [ARCHIVED VERSION]
│  └─ ServiceConnection-Helper-OLD.ps1
└─ 📄 [OTHER REFERENCE FILES]
```

---

## Next Steps

### Ready to Start?

1. Open [PREREQUISITES.md](PREREQUISITES.md)
2. Verify you have all requirements
3. Run: `.\ServiceConnection-Helper.ps1`
4. Follow the 4-step menu
5. Use [SETUP-GUIDE.md](SETUP-GUIDE.md) as reference

### Estimated Time: 15-20 minutes

---

## Version Information

- **Current Version**: 2.0
- **Release Date**: January 12, 2026
- **Status**: Production Ready
- **Tested**: Yes
- **Documentation**: Complete

---

## Questions?

1. **About requirements?** → [PREREQUISITES.md](PREREQUISITES.md)
2. **Step-by-step help?** → [SETUP-GUIDE.md](SETUP-GUIDE.md)
3. **What changed?** → [VERSION-2.0-RELEASE.md](VERSION-2.0-RELEASE.md)
4. **Is everything ready?** → [DEPLOYMENT-READY.md](DEPLOYMENT-READY.md)

---

**Start with [README.md](README.md) - takes 5 minutes!**

Then follow [SETUP-GUIDE.md](SETUP-GUIDE.md) - 15-20 minutes to complete setup.

---

Last Updated: January 12, 2026  
Status: ✅ PRODUCTION READY
