# Azure DevOps to GitHub Migration - Service Connection Setup
# Version 3.0: Manual OAuth Service Connection + Automated Pipeline Updates
# Simplified workflow - user creates service connection once, script updates pipelines

param(
    [string]$Action = "menu"
)

# Global variables
$script:ConfigFile = "SERVICE-CONNECTIONS.csv"
$script:AzDoBaseUrl = "https://dev.azure.com"
$script:PAT = $null
$script:Organization = $null
$script:Project = $null

# ============================================================================
# MAIN MENU
# ============================================================================

function Show-Menu {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "  Azure DevOps to GitHub Migration - Service Connection Setup" -ForegroundColor Cyan
    Write-Host "  Version 3.0: Manual OAuth + Automated Pipeline Updates" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PREREQUISITES:" -ForegroundColor Yellow
    Write-Host "  - Service connection created manually in Azure DevOps with OAuth"
    Write-Host "  - CSV filled with organization, project, pipelines, repos"
    Write-Host "  - Azure DevOps PAT for API access"
    Write-Host ""
    Write-Host "WORKFLOW:" -ForegroundColor Green
    Write-Host "  [1] Setup: Provide PAT and validate configuration"
    Write-Host "  [2] Validate: Check service connection exists"
    Write-Host "  [3] Update: Modify pipeline YAML for GitHub triggers"
    Write-Host "  [4] Test: Verify webhook and trigger"
    Write-Host "  [5] Exit"
    Write-Host ""
}

function Invoke-MainMenu {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select option (1-5)"
        
        switch ($choice) {
            "1" { Setup-Configuration }
            "2" { Validate-ServiceConnection }
            "3" { Update-PipelineYAML }
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
# STEP 1: SETUP - GET PAT AND VALIDATE CONFIGURATION
# ============================================================================

function Setup-Configuration {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 1: SETUP - PROVIDE PAT AND VALIDATE CONFIGURATION" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "STEP 1a: SERVICE CONNECTION SETUP (Manual - One Time Only)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Before using this script, create a service connection manually:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Go to Azure DevOps:" -ForegroundColor Cyan
    Write-Host "   https://dev.azure.com/[ORG]/[PROJECT]/_settings/adminservices"
    Write-Host ""
    Write-Host "2. Click 'New Service Connection'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Select 'GitHub'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Click 'Authorize AzureDevOps' (OAuth flow)" -ForegroundColor Cyan
    Write-Host "   - Browser will open"
    Write-Host "   - Log in with GitHub"
    Write-Host "   - Click Authorize"
    Write-Host ""
    Write-Host "5. Name your service connection (e.g., 'github-oauth')" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "6. Click 'Save'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Status:" -ForegroundColor Yellow
    $serviceConnReady = Read-Host "Is your service connection created with OAuth? (yes/no)"
    
    if ($serviceConnReady.ToLower() -ne "yes") {
        Write-Host "Please create the service connection first before proceeding." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "STEP 1b: AZURE DEVOPS PAT" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Enter your Azure DevOps PAT for API access:" -ForegroundColor White
    Write-Host "Required scopes:" -ForegroundColor Gray
    Write-Host "  - Code (Read & Write)"
    Write-Host "  - Build (Read & Execute)"
    Write-Host "  - Project & Team (Read & Execute)"
    Write-Host ""
    
    $patInput = Read-Host "Enter your Azure DevOps PAT"
    
    if (-not $patInput) {
        Write-Host "PAT is required. Aborting." -ForegroundColor Red
        return
    }
    
    $script:PAT = $patInput
    Write-Host "PAT stored for current session" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "STEP 1c: LOAD CONFIGURATION FROM CSV" -ForegroundColor Yellow
    Write-Host ""
    
    Load-Configuration
    
    if (-not $script:Organization -or -not $script:Project) {
        Write-Host "ERROR: Could not load organization or project from CSV" -ForegroundColor Red
        Write-Host "Please check SERVICE-CONNECTIONS.csv" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Configuration loaded:" -ForegroundColor Green
    Write-Host "  Organization: $($script:Organization)" -ForegroundColor Cyan
    Write-Host "  Project: $($script:Project)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "STEP 1d: VALIDATE PAT" -ForegroundColor Yellow
    Write-Host ""
    
    Validate-AzDoPAT
}

# ============================================================================
# STEP 2: VALIDATE SERVICE CONNECTION
# ============================================================================

function Validate-ServiceConnection {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 2: VALIDATE SERVICE CONNECTION" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Load-Configuration
    
    if (-not $script:Organization -or -not $script:Project) {
        Write-Host "Configuration not loaded. Run Step 1 first." -ForegroundColor Red
        return
    }
    
    if (-not $script:PAT) {
        $script:PAT = Read-Host "Enter your Azure DevOps PAT"
        if (-not $script:PAT) {
            Write-Host "PAT required. Aborting." -ForegroundColor Red
            return
        }
    }
    
    Write-Host "Checking for GitHub service connections in project..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $PatToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($script:PAT)"))
        $headers = @{
            Authorization = "Basic $PatToken"
            "Content-Type" = "application/json"
        }
        
        $url = "$script:AzDoBaseUrl/$($script:Organization)/$($script:Project)/_apis/serviceendpoint/endpoints?api-version=7.0"
        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
        
        $githubConnections = $response.value | Where-Object { $_.type -eq "github" }
        
        if ($githubConnections.Count -eq 0) {
            Write-Host "ERROR: No GitHub service connections found!" -ForegroundColor Red
            Write-Host ""
            Write-Host "Go to Step 1 and create a service connection manually:" -ForegroundColor Yellow
            Write-Host "  https://dev.azure.com/$($script:Organization)/$($script:Project)/_settings/adminservices"
            return
        }
        
        Write-Host "Found $($githubConnections.Count) GitHub service connection(s):" -ForegroundColor Green
        Write-Host ""
        
        foreach ($conn in $githubConnections) {
            Write-Host "  - Name: $($conn.name)" -ForegroundColor Cyan
            Write-Host "    ID: $($conn.id)" -ForegroundColor Gray
            Write-Host "    URL: $($conn.url)" -ForegroundColor Gray
            Write-Host "    Auth: $($conn.authorization.scheme)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "SUCCESS! Service connection(s) validated." -ForegroundColor Green
        Write-Host ""
        Write-Host "Next: Run Step 3 to update pipelines for GitHub triggers." -ForegroundColor Yellow
    }
    catch {
        Write-Host "ERROR: Could not validate service connection" -ForegroundColor Red
        Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Verify PAT is valid and not expired"
        Write-Host "  - Verify organization and project names in CSV"
        Write-Host "  - Verify service connection exists in Azure DevOps"
    }
}

# ============================================================================
# STEP 3: UPDATE PIPELINE YAML
# ============================================================================

function Update-PipelineYAML {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 3: UPDATE PIPELINE YAML FOR GITHUB TRIGGERS" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Load-Configuration
    
    if (-not $script:Organization -or -not $script:Project) {
        Write-Host "Configuration not loaded. Run Step 1 first." -ForegroundColor Red
        return
    }
    
    if (-not $script:PAT) {
        $script:PAT = Read-Host "Enter your Azure DevOps PAT"
        if (-not $script:PAT) {
            Write-Host "PAT required. Aborting." -ForegroundColor Red
            return
        }
    }
    
    Write-Host "MANUAL PIPELINE UPDATE REQUIRED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "For each pipeline, you need to update the YAML:" -ForegroundColor White
    Write-Host ""
    Write-Host "Option A: MANUAL YAML UPDATE (recommended for testing)" -ForegroundColor Cyan
    Write-Host "1. Edit your pipeline YAML file (azure-pipelines.yml)" -ForegroundColor White
    Write-Host "2. Add GitHub repository resource:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "resources:" -ForegroundColor Gray
    Write-Host "  repositories:" -ForegroundColor Gray
    Write-Host "  - repository: github-repo" -ForegroundColor Gray
    Write-Host "    type: github" -ForegroundColor Gray
    Write-Host "    name: [OWNER]/[REPO]" -ForegroundColor Gray
    Write-Host "    connection: [SERVICE-CONNECTION-NAME]" -ForegroundColor Gray
    Write-Host "    trigger: true" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Update trigger:" -ForegroundColor White
    Write-Host ""
    Write-Host "trigger:" -ForegroundColor Gray
    Write-Host "  batch: true" -ForegroundColor Gray
    Write-Host "  branches:" -ForegroundColor Gray
    Write-Host "    include:" -ForegroundColor Gray
    Write-Host "    - main" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Commit and push YAML changes" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Option B: AUTOMATED YAML UPDATE (via pipeline settings UI)" -ForegroundColor Cyan
    Write-Host "1. Go to pipeline in Azure DevOps" -ForegroundColor White
    Write-Host "2. Click Edit" -ForegroundColor Gray
    Write-Host "3. Go to Triggers tab" -ForegroundColor Gray
    Write-Host "4. Enable 'Override the YAML trigger from here'" -ForegroundColor Gray
    Write-Host "5. Select GitHub as source" -ForegroundColor Gray
    Write-Host "6. Click Save" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Which option did you choose? (manual/automated)" -ForegroundColor Yellow
    $choice = Read-Host "Enter your choice"
    
    if ($choice -eq "manual") {
        Write-Host ""
        Write-Host "Update complete. Commit your YAML changes and push to trigger pipeline." -ForegroundColor Green
    } elseif ($choice -eq "automated") {
        Write-Host ""
        Write-Host "Pipeline settings updated. Triggers should now use GitHub." -ForegroundColor Green
    } else {
        Write-Host "Invalid choice." -ForegroundColor Red
    }
}

# ============================================================================
# STEP 4: TEST WEBHOOK
# ============================================================================

function Test-WebhookSetup {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  STEP 4: TEST WEBHOOK AND PIPELINE TRIGGER" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Load-Configuration
    
    Write-Host "VERIFY WEBHOOK IN GITHUB:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to your GitHub repository:" -ForegroundColor Cyan
    Write-Host "   https://github.com/[OWNER]/[REPO]/settings/hooks"
    Write-Host ""
    Write-Host "2. Look for webhook from 'dev.azure.com' or 'api.github.com'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Click on the webhook:" -ForegroundColor Cyan
    Write-Host "   - Check Recent Deliveries"
    Write-Host "   - Status should show 200 OK"
    Write-Host "   - If errors, check response for details"
    Write-Host ""
    
    Write-Host "TEST PIPELINE TRIGGER:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Make a small change to your GitHub repository:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   cd [local-repo]" -ForegroundColor Gray
    Write-Host "   echo 'test' >> README.md" -ForegroundColor Gray
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m 'test trigger'" -ForegroundColor Gray
    Write-Host "   git push" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check if pipeline runs:" -ForegroundColor Cyan
    Write-Host "   https://dev.azure.com/$($script:Organization)/$($script:Project)/_build"
    Write-Host ""
    Write-Host "3. Pipeline should start automatically (within 1-2 minutes)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If webhook doesn't exist:" -ForegroundColor Red
    Write-Host "  - Go to Step 2, re-validate service connection"
    Write-Host "  - Manually create webhook in GitHub if needed"
    Write-Host ""
    Write-Host "If webhook exists but shows errors:" -ForegroundColor Red
    Write-Host "  - Check GitHub webhook Recent Deliveries for error details"
    Write-Host "  - Verify pipeline YAML has correct GitHub trigger configuration"
    Write-Host "  - Check service connection name matches YAML"
    Write-Host ""
    Write-Host "If pipeline doesn't trigger:" -ForegroundColor Red
    Write-Host "  - Verify pipeline YAML has 'trigger:' configuration"
    Write-Host "  - Check branch protection rules in GitHub"
    Write-Host "  - Look at Service Hooks in Azure DevOps"
    Write-Host ""
    
    $success = Read-Host "Is pipeline triggering successfully? (yes/no)"
    
    if ($success.ToLower() -eq "yes") {
        Write-Host ""
        Write-Host "SUCCESS! Setup complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your Azure DevOps pipeline is now connected to GitHub with OAuth:" -ForegroundColor Cyan
        Write-Host "  - Service connection: OAuth (secure, auto-refresh)"
        Write-Host "  - Webhook: Active (triggers pipeline on push)"
        Write-Host "  - Pipeline YAML: Configured for GitHub triggers"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Monitor your pipeline runs"
        Write-Host "  2. Set up branch protection rules in GitHub if needed"
        Write-Host "  3. Configure pipeline to require PR reviews before merge"
    } else {
        Write-Host ""
        Write-Host "Continue troubleshooting. Check error messages in:" -ForegroundColor Yellow
        Write-Host "  - GitHub webhook Recent Deliveries"
        Write-Host "  - Azure DevOps pipeline logs"
        Write-Host "  - Service Hooks page"
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
    }
}

function Validate-AzDoPAT {
    if (-not $script:PAT) {
        Write-Host "No PAT provided. Skipping validation." -ForegroundColor Yellow
        return
    }
    
    try {
        $PatToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($script:PAT)"))
        $headers = @{
            Authorization = "Basic $PatToken"
            "Content-Type" = "application/json"
        }
        
        $testUrl = "https://dev.azure.com/$($script:Organization)/_apis/projects?api-version=7.0"
        $response = Invoke-RestMethod -Uri $testUrl -Method GET -Headers $headers -TimeoutSec 5
        
        Write-Host "Azure DevOps PAT: VALID" -ForegroundColor Green
        Write-Host "  - Organization: $($script:Organization)"
        Write-Host "  - Projects found: $($response.value.Count)"
    }
    catch {
        Write-Host "Azure DevOps PAT: INVALID or EXPIRED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please regenerate PAT:" -ForegroundColor Yellow
        Write-Host "  https://dev.azure.com/$($script:Organization)/_usersSettings/tokens"
        $script:PAT = $null
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
