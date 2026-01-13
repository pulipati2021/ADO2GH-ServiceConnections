# Prerequisites for Azure DevOps to GitHub Service Connection Migration

## Overview
This document outlines all prerequisites needed before starting the service connection setup process.

---

## 1. GitHub Permissions (CRITICAL)

### Required Permissions:
- **Owner** permission on the GitHub Organization
- **Admin** permission on the GitHub Repository

### Why These Permissions Matter:
- **Owner permission**: Allows OAuth authorization for organization-level access
- **Admin permission**: Required for creating webhooks on the repository
- **Without these**: OAuth will fail and webhooks cannot be created

### How to Check Your Permissions:

#### Check Organization Owner Permission:
1. Go to: `https://github.com/orgs/[YOUR-ORG]/people`
2. Find your username in the list
3. Verify your role shows as "Owner"

#### Check Repository Admin Permission:
1. Go to: `https://github.com/[OWNER]/[REPO]/settings/access`
2. Find your username
3. Verify role shows as "Admin"

### If You Don't Have Permissions:
1. **Request from Organization Admin**:
   - Send request to your GitHub Organization administrator
   - Provide your GitHub username
   - Request: "Owner permission on Organization and Admin permission on Repository [NAME]"

2. **Wait for Approval**:
   - Administrator will need to approve the permission upgrade
   - This may take 24-48 hours

3. **Verify After Approval**:
   - Check the links above after 1-2 hours
   - Refresh the page to see updated permissions
   - Only proceed once permissions show as approved

---

## 2. Azure DevOps Personal Access Token (PAT)

### What is a PAT?
A Personal Access Token is like a password for programmatic access to Azure DevOps.

### Required Scopes:
Your PAT must have these scopes enabled:
- ✓ **Code**: Read & Write
- ✓ **Release**: Read & Write  
- ✓ **Endpoint**: Read & Execute & Manage
- ✓ **Build**: Read & Execute

### How to Create a PAT:

1. **Go to Azure DevOps User Settings**:
   - URL: `https://dev.azure.com/[ORGANIZATION]/_usersSettings/tokens`
   - Or: Click your profile icon (top-right) → Personal access tokens

2. **Create New Token**:
   - Click "New Token" button
   - Enter name: `GitHub-Migration-[DATE]` (e.g., `GitHub-Migration-Jan2026`)
   - Select expiration: `90 days` (or as required by your organization)

3. **Set Scopes**:
   - Expand "Custom defined"
   - Check the following:
     - ✓ Code (Read & Write)
     - ✓ Release (Read & Write)
     - ✓ Build (Read & Execute)
     - ✓ Endpoint (Read & Execute & Manage)

4. **Create and Save**:
   - Click "Create" button
   - Copy the token immediately (you won't see it again!)
   - Save it in a secure location
   - Use this token when prompted during setup

### Security Notes:
- **Do NOT share** your PAT with anyone
- **Do NOT commit** to version control
- **Revoke immediately** if compromised
- **Set expiration date** for temporary tokens (recommended)

---

## 3. GitHub Personal Access Token (For Service Connection)

### What is a GitHub PAT?
Allows Azure DevOps to authenticate with GitHub on your behalf.

### Required Scopes:
- ✓ **repo**: Full control of private repositories
- ✓ **admin:repo_hook**: Full control of repository hooks
- ✓ **read:org**: Read organization data

### How to Create:

1. **Go to GitHub Settings**:
   - URL: `https://github.com/settings/tokens`
   - Or: Profile icon (top-right) → Settings → Developer settings → Personal access tokens

2. **Generate New Token**:
   - Click "Generate new token"
   - Token name: `AzDo-Migration-[DATE]` (e.g., `AzDo-Migration-Jan2026`)
   - Expiration: `90 days` (recommended)

3. **Select Scopes**:
   - ✓ `repo` (all of it)
   - ✓ `admin:repo_hook`
   - ✓ `read:org`

4. **Generate and Save**:
   - Click "Generate token"
   - Copy immediately (won't be visible again)
   - Save in secure location

### Security Notes:
- Keep separate from Azure DevOps PAT
- **Do NOT share** with anyone
- **Revoke immediately** if compromised
- Only used during service connection creation (Step 2)

---

## 4. Repository Information

You'll need these details ready:

| Item | Example | Where to Find |
|------|---------|---------------|
| **Organization** | `git-AzDo` | Azure DevOps URL: `dev.azure.com/[ORG]` |
| **Project** | `Calamos-Test` | Azure DevOps → Project name |
| **Repository Owner** | `im-sandbox-phanirb` | GitHub: `github.com/[OWNER]/[REPO]` |
| **Repository Name** | `AzureRepoCode-CalamosTest` | GitHub: `github.com/[OWNER]/[REPO]` |
| **Service Connection Name** | `sc_oath` | Name you want to give this connection |

---

## 5. Access Requirements

### Azure DevOps Access:
- ✓ Must be able to access your organization
- ✓ Must have permission to create service connections in the project
- ✓ Must have permission to edit pipelines

### GitHub Access:
- ✓ Must be able to access the repository
- ✓ Must have owner/admin permissions (as listed above)
- ✓ Web browser (for OAuth authentication)

---

## 6. Pre-Flight Checklist

Before running the setup script, verify all items:

### GitHub Permissions:
- [ ] Organization Owner permission verified
- [ ] Repository Admin permission verified
- [ ] Permission request submitted (if needed)
- [ ] Waited 24+ hours for approval (if requested)

### Azure DevOps:
- [ ] Can access Azure DevOps organization
- [ ] Azure DevOps PAT created and saved
- [ ] GitHub PAT created and saved
- [ ] Repository information collected

### Environment:
- [ ] Windows PowerShell 5.1 or higher
- [ ] Web browser available (for OAuth)
- [ ] Network access to both Azure DevOps and GitHub
- [ ] Not behind restrictive corporate firewall

---

## 7. Troubleshooting Permission Issues

### "Permission Denied" Error:
**Problem**: OAuth fails with permission denied  
**Solution**: 
- Verify you have Owner permission on organization
- Try in private/incognito browser window
- Clear GitHub cookies and try again

### "Repository Not Found":
**Problem**: Cannot select repository during setup  
**Solution**:
- Verify Admin permission on specific repository
- Ensure repository name is correct
- Check repository is not deleted or renamed

### "Webhook Failed to Create":
**Problem**: OAuth succeeds but webhook doesn't appear in GitHub  
**Solution**:
- Re-authenticate in pipeline settings
- Click Save again to trigger webhook creation
- Verify Admin permission on repository

---

## 8. Next Steps

Once all prerequisites are met:

1. **Run the Setup Script**:
   ```powershell
   cd 'C:\Users\Pulipati\Desktop\INFOMAGNUS\...\service-connections-NoPipelineMigration'
   .\ServiceConnection-Helper.ps1
   ```

2. **Follow the 4-Step Process**:
   - Step 1: Check Prerequisites & Read PAT
   - Step 2: Create Service Connection with PAT
   - Step 3: Configure Pipeline Trigger (GitHub OAuth)
   - Step 4: Test and Verify Webhook

3. **Verify Success**:
   - Webhook appears in GitHub repository settings
   - Pipeline triggers on code push
   - Both repositories stay in sync

---

## Contact & Support

If you encounter issues:
1. Check the troubleshooting section in this document
2. Review error messages carefully
3. Verify all prerequisites are met
4. Check README.md for additional information

---

**Last Updated**: January 12, 2026  
**Version**: 2.0 (PAT-based with GitHub OAuth)
