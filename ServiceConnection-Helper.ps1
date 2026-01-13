# Azure DevOps to GitHub Migration - Service Connection Setup
# Simplified workflow based on actual tested process
# Version: 2.0 (PAT-based with manual pipeline trigger configuration)

param(
    [string]$Action = "menu"
)

# Global variables
$script:ConfigFile = "SERVICE-CONNECTIONS.csv"
$script:AzDoBaseUrl = "https://dev.azure.com"
$script:PAT = $null
$script:Organization = $null
$script:Project = $null
$script:RepositoryName = $null
$script:ServiceConnectionName = $null

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-Menu {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "  Azure DevOps to GitHub Service Connection Migration" -ForegroundColor Cyan
    Write-Host "  PAT-Based Service Connection with GitHub OAuth Pipeline Trigger" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PREREQUISITES:" -ForegroundColor Yellow
    Write-Host "  - GitHub Owner permission on Organization"
    Write-Host "  - GitHub Admin permission on Repository"
    Write-Host "  - Azure DevOps PAT (Personal Access Token)"
    Write-Host ""
    Write-Host "WORKFLOW:" -ForegroundColor Green
    Write-Host "  [1] Check Prerequisites & Read PAT"
    Write-Host "  [2] Create Service Connection with PAT"
    Write-Host "  [3] Configure Pipeline Trigger (GitHub OAuth)"
    Write-Host "  [4] Test and Verify Webhook"
    Write-Host "  [5] Exit"
    Write-Host ""
}

function Invoke-MainMenu {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select option (1-5)"
        
        switch ($choice) {
            "1" { Check-Prerequisites }
            "2" { Create-ServiceConnectionWithPAT }
            "3" { Configure-PipelineTrigger }
            "4" { Test-WebhookSetup }
            "5" { exit }
            default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
        }
        
        if ($choice -ne "5") {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    }
}

# ============================================================================
# STEP 1: CHECK PREREQUISITES
# ============================================================================

function Check-Prerequisites {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 1: CHECK PREREQUISITES & READ PAT" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "GITHUB PERMISSIONS CHECK:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Before proceeding, verify you have:" -ForegroundColor White
    Write-Host "  1. OWNER permission on the GitHub Organization" -ForegroundColor Gray
    Write-Host "  2. ADMIN permission on the GitHub Repository" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To check your permissions:" -ForegroundColor Yellow
    Write-Host "  1. Go to https://github.com/orgs/[ORG]/people (Owner permissions)"
    Write-Host "  2. Go to https://github.com/[OWNER]/[REPO]/settings/access (Admin permissions)"
    Write-Host ""
    Write-Host "If you don't have these permissions:" -ForegroundColor Red
    Write-Host "  - Request from your GitHub Organization administrator"
    Write-Host "  - Wait for approval before continuing"
    Write-Host ""
    
    $permissionsOK = Read-Host "Do you have required GitHub permissions? (yes/no)"
    
    if ($permissionsOK.ToLower() -ne "yes") {
        Write-Host "Please obtain required permissions before continuing." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "AZURE DEVOPS PAT SETUP:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You need a Personal Access Token (PAT) for Azure DevOps." -ForegroundColor White
    Write-Host "Required scopes:" -ForegroundColor Gray
    Write-Host "  - Code (Read & Write)"
    Write-Host "  - Release (Read & Write)"
    Write-Host "  - Endpoint (Read & Execute & Manage)"
    Write-Host ""
    
    $patInput = Read-Host "Enter your Azure DevOps PAT (or press Enter to skip for now)"
    
    if ($patInput) {
        $script:PAT = $patInput
        Write-Host "PAT stored for current session" -ForegroundColor Green
    } else {
        Write-Host "Skipped. You will provide PAT in next steps." -ForegroundColor Yellow
    }
    
    # Load configuration
    Load-Configuration
}

# ============================================================================
# STEP 2: CREATE SERVICE CONNECTION WITH PAT
# ============================================================================

function Create-ServiceConnectionWithPAT {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 2: CREATE SERVICE CONNECTION WITH PAT" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Ensure we have PAT
    if (-not $script:PAT) {
        $script:PAT = Read-Host "Enter your Azure DevOps PAT"
        if (-not $script:PAT) {
            Write-Host "PAT is required. Aborting." -ForegroundColor Red
            return
        }
    }
    
    # Load configuration
    Load-Configuration
    
    if (-not $script:Organization -or -not $script:Project) {
        Write-Host "Configuration not loaded. Please run Step 1 first." -ForegroundColor Red
        return
    }
    
    Write-Host "Using configuration:" -ForegroundColor White
    Write-Host "  Organization: $($script:Organization)" -ForegroundColor Cyan
    Write-Host "  Project: $($script:Project)" -ForegroundColor Cyan
    Write-Host "  Repository: $($script:RepositoryName)" -ForegroundColor Cyan
    Write-Host "  Service Connection: $($script:ServiceConnectionName)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Creating service connection using PAT method..." -ForegroundColor Yellow
    Write-Host ""
    
    # Use Azure DevOps REST API to create service connection
    $createUrl = "$script:AzDoBaseUrl/$($script:Organization)/$($script:Project)/_apis/serviceendpoint/endpoints?api-version=7.0"
    
    # PAT must be encoded as base64 for Basic auth
    $PatToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($script:PAT)"))
    $headers = @{
        Authorization = "Basic $PatToken"
        "Content-Type" = "application/json"
    }
    
    # GitHub PAT service connection payload
    $githubPAT = Read-Host "Enter your GitHub PAT (for service connection)"
    
    $body = @{
        name = $script:ServiceConnectionName
        type = "github"
        url = "https://github.com"
        authorization = @{
            scheme = "PersonalAccessToken"
            parameters = @{
                accessToken = $githubPAT
            }
        }
        isShared = $false
        isReady = $true
        description = "GitHub service connection for Azure DevOps pipeline integration"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $createUrl -Method POST -Headers $headers -Body $body
        Write-Host "Service connection created successfully!" -ForegroundColor Green
        Write-Host "  ID: $($response.id)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "IMPORTANT: Go to Step 3 to configure pipeline trigger with OAuth." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error creating service connection:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Verify PAT has correct scopes (Code, Release, Endpoint)"
        Write-Host "  - Verify GitHub PAT has repo and admin:repo_hook scopes"
        Write-Host "  - Check organization and project names are correct"
    }
}

# ============================================================================
# STEP 3: CONFIGURE PIPELINE TRIGGER
# ============================================================================

function Configure-PipelineTrigger {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 3: CONFIGURE PIPELINE TRIGGER WITH GITHUB OAUTH" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Load-Configuration
    
    Write-Host "MANUAL CONFIGURATION REQUIRED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This step requires manual configuration in Azure DevOps UI:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Open Azure DevOps:" -ForegroundColor Cyan
    Write-Host "   $script:AzDoBaseUrl/$($script:Organization)/$($script:Project)/_build"
    Write-Host ""
    Write-Host "2. Select your pipeline and click Edit" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Go to Triggers tab" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Under 'Pull request validation':" -ForegroundColor Cyan
    Write-Host "   - Enable continuous integration"
    Write-Host ""
    Write-Host "5. Change source repository:" -ForegroundColor Cyan
    Write-Host "   - Click dropdown showing 'Azure Repos Git'"
    Write-Host "   - Select 'GitHub'" -ForegroundColor Green
    Write-Host "   - Authenticate with OAuth (browser popup will appear)"
    Write-Host "   - Authorize Azure DevOps access to GitHub"
    Write-Host ""
    Write-Host "6. Select the GitHub repository:" -ForegroundColor Cyan
    Write-Host "   - Choose: $($script:RepositoryName)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "7. Configure trigger events:" -ForegroundColor Cyan
    Write-Host "   - Default: 'Push' will be selected"
    Write-Host "   - You can also add: Pull request, Issues, etc."
    Write-Host ""
    Write-Host "8. Save the pipeline" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WHAT HAPPENS AUTOMATICALLY:" -ForegroundColor Green
    Write-Host "  - Webhook created in GitHub repository automatically"
    Write-Host "  - Pipeline now triggered by GitHub events (push/PR)"
    Write-Host "  - OAuth authentication established"
    Write-Host ""
    
    $ready = Read-Host "Have you completed the OAuth configuration in Azure DevOps? (yes/no)"
    
    if ($ready.ToLower() -eq "yes") {
        Write-Host "Configuration complete. Proceed to Step 4 to test." -ForegroundColor Green
    } else {
        Write-Host "Please complete the OAuth configuration before testing." -ForegroundColor Yellow
    }
}

# ============================================================================
# STEP 4: TEST AND VERIFY WEBHOOK
# ============================================================================

function Test-WebhookSetup {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 4: TEST AND VERIFY WEBHOOK SETUP" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Load-Configuration
    
    Write-Host "VERIFY WEBHOOK IN GITHUB:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to GitHub repository settings:" -ForegroundColor Cyan
    Write-Host "   https://github.com/$($script:RepositoryName)/settings/hooks"
    Write-Host ""
    Write-Host "2. Look for webhook from 'azure.com' or 'dev.azure.com'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Click on it and check:" -ForegroundColor Cyan
    Write-Host "   - Recent Deliveries tab shows successful deliveries"
    Write-Host "   - Delivery shows '200 OK' response"
    Write-Host ""
    
    Write-Host "TEST PIPELINE TRIGGER:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Make a small change to code in your GitHub repository" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Push the change:" -ForegroundColor Cyan
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m 'test trigger'" -ForegroundColor Gray
    Write-Host "   git push" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Check if pipeline runs:" -ForegroundColor Cyan
    Write-Host "   Go to: $script:AzDoBaseUrl/$($script:Organization)/$($script:Project)/_build"
    Write-Host "   Look for new pipeline run"
    Write-Host "   Should start automatically after push"
    Write-Host ""
    
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If webhook not created:" -ForegroundColor Red
    Write-Host "  - Go back to Step 3 and re-authenticate OAuth"
    Write-Host "  - Click Save on pipeline settings to trigger webhook creation"
    Write-Host ""
    Write-Host "If webhook exists but no trigger:" -ForegroundColor Red
    Write-Host "  - Check webhook in GitHub (Recent Deliveries tab)"
    Write-Host "  - Verify error message in delivery response"
    Write-Host "  - Check pipeline YAML uses trigger: auto or branches: config"
    Write-Host ""
    
    $verified = Read-Host "Is webhook working and pipeline triggering? (yes/no)"
    
    if ($verified.ToLower() -eq "yes") {
        Write-Host "SUCCESS! Service connection and webhook are working." -ForegroundColor Green
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "  1. All pushes to GitHub will now trigger Azure DevOps pipeline"
        Write-Host "  2. Check both repository sites for sync status"
        Write-Host "  3. Monitor first few pipeline runs for any issues"
    } else {
        Write-Host "Continue troubleshooting. Check logs and permissions." -ForegroundColor Yellow
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Load-Configuration {
    if (-not (Test-Path $script:ConfigFile)) {
        Write-Host "Configuration file not found: $script:ConfigFile" -ForegroundColor Red
        return
    }
    
    $csv = Import-Csv $script:ConfigFile
    if ($csv) {
        $script:Organization = $csv[0].Organization
        $script:Project = $csv[0].ProjectName
        $script:RepositoryName = $csv[0].RepositoryName
        $script:ServiceConnectionName = $csv[0].ServiceConnectionName
    }
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if ($Action -eq "menu") {
    Invoke-MainMenu
} elseif ($Action -eq "noop") {
    # No operation - used for syntax testing
}
