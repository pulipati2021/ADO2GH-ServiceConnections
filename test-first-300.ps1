param(
    [Parameter(Mandatory = $false)]
    [string]$Action = "menu"
)

# Colors for output
$Colors = @{
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
}

# Global variables for credentials
$Global:GitHubPAT = $null
$Global:AzureDevOpsPAT = $null
$Global:SessionInitialized = $false

function Show-AuthStatus {
    Write-Host ""
    Write-Host "Authentication Status:" -ForegroundColor Cyan
    if ($Global:GitHubPAT) {
        Write-Host "  [OK] GitHub PAT: PROVIDED" -ForegroundColor Green
    } else {
        Write-Host "  [--] GitHub PAT: NOT PROVIDED" -ForegroundColor Red
    }
    if ($Global:AzureDevOpsPAT) {
        Write-Host "  [OK] Azure DevOps PAT: PROVIDED" -ForegroundColor Green
    } else {
        Write-Host "  [--] Azure DevOps PAT: NOT PROVIDED" -ForegroundColor Red
    }
    Write-Host ""
}

function Show-Menu {
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "   Service Connection Helper - GitHub <> Azure DevOps" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Show-AuthStatus
    Write-Host "1. Create Service Connection (PAT-based)" -ForegroundColor Yellow
    Write-Host "2. Create Service Connection (OAuth-based) [RECOMMENDED]" -ForegroundColor Green
    Write-Host "3. Validate Service Connection" -ForegroundColor Yellow
    Write-Host "4. Test GitHub Webhook" -ForegroundColor Yellow
    Write-Host "5. Create Webhook Only (for Existing Service Connections)" -ForegroundColor Yellow
    Write-Host "6. Update Pipeline YAML for GitHub Triggers [AUTOMATED]" -ForegroundColor Green
    Write-Host "7. View Service Connections" -ForegroundColor Yellow
    Write-Host "8. View CSV Data" -ForegroundColor Yellow
    Write-Host "9. Manage Authentication (Add/Remove PATs)" -ForegroundColor Yellow
    Write-Host "10. Quick Setup Wizard (Guided Workflow)" -ForegroundColor Magenta
    Write-Host "11. Exit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
}

function Read-ServiceConnectionCSV {
    $csvPath = Join-Path (Get-Location) "SERVICE-CONNECTIONS.csv"
    if (-not (Test-Path $csvPath)) {
        Write-Host "ERROR: SERVICE-CONNECTIONS.csv not found!" -ForegroundColor Red
        return $null
    }
    return Import-Csv -Path $csvPath
}

function Show-CSVData {
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    Write-Host ""
    Write-Host "Service Connections Data:" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    $data | Format-Table -AutoSize
    Write-Host ""
}

function Get-SecurePAT {
    param(
        [string]$Name
    )
    $secureInput = Read-Host "Enter $Name" -AsSecureString
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($secureInput))
}

function Initialize-Session {
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "   Session Initialization - Authentication Setup" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Provide your credentials (they will remain in memory for this session only):" -ForegroundColor Cyan
    Write-Host ""
    
    $Global:GitHubPAT = Get-SecurePAT "GitHub PAT"
    Write-Host "[OK] GitHub PAT stored in session" -ForegroundColor Green
    Write-Host ""
    
    $Global:AzureDevOpsPAT = Get-SecurePAT "Azure DevOps PAT"
    Write-Host "[OK] Azure DevOps PAT stored in session" -ForegroundColor Green
    
    $Global:SessionInitialized = $true
    Write-Host ""
    Write-Host "Session initialized. Starting menu..." -ForegroundColor Green
    Read-Host "Press Enter to continue"
}

function Manage-Authentication {
    Write-Host ""
    Write-Host "Manage Authentication:" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Show-AuthStatus
    
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "1. Add GitHub PAT"
    Write-Host "2. Add Azure DevOps PAT"
    Write-Host "3. Clear GitHub PAT"
    Write-Host "4. Clear Azure DevOps PAT"
    Write-Host "5. Clear All PATs"
    Write-Host "6. Go back"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" {
            $Global:GitHubPAT = Get-SecurePAT "GitHub PAT"
            Write-Host "[OK] GitHub PAT updated" -ForegroundColor Green
        }
        "2" {
            $Global:AzureDevOpsPAT = Get-SecurePAT "Azure DevOps PAT"
            Write-Host "[OK] Azure DevOps PAT updated" -ForegroundColor Green
        }
        "3" {
            $Global:GitHubPAT = $null
            Write-Host "[OK] GitHub PAT cleared" -ForegroundColor Green
        }
        "4" {
            $Global:AzureDevOpsPAT = $null
            Write-Host "[OK] Azure DevOps PAT cleared" -ForegroundColor Green
        }
        "5" {
            $Global:GitHubPAT = $null
            $Global:AzureDevOpsPAT = $null
            Write-Host "[OK] All PATs cleared" -ForegroundColor Green
        }
        "6" { return }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }
    
    Read-Host "Press Enter to continue"
}

function Invoke-GuidedWorkflow {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Magenta
    Write-Host "   QUICK SETUP WIZARD - Complete Automated Workflow" -ForegroundColor Magenta
    Write-Host "========================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "This wizard will guide you through the complete setup process." -ForegroundColor Cyan
    Write-Host "Each option handles everything automatically - no wrong choices!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Choose your preferred setup method:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "A) PAT-Based Setup (Quick, uses GitHub Personal Access Token)" -ForegroundColor Yellow
    Write-Host "   - Fast: ~2-3 minutes" -ForegroundColor Gray
    Write-Host "   - Creates service connection + webhooks automatically" -ForegroundColor Gray
    Write-Host "   - Then updates pipeline YAML" -ForegroundColor Gray
    Write-Host ""
    Write-Host "B) OAuth Setup (RECOMMENDED - Most Reliable)" -ForegroundColor Green
    Write-Host "   - Takes ~3-4 minutes (includes browser authorization)" -ForegroundColor Gray
    Write-Host "   - Azure DevOps auto-refreshes tokens (no expiration issues)" -ForegroundColor Gray
    Write-Host "   - Webhooks never fail with 401 errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "C) Manual Service Connection (You already created one)" -ForegroundColor Yellow
    Write-Host "   - Creates webhooks for existing service connection" -ForegroundColor Gray
    Write-Host "   - Then updates pipeline YAML" -ForegroundColor Gray
    Write-Host ""
    $workflowChoice = Read-Host "Select setup method (A/B/C)"
    
    switch ($workflowChoice.ToUpper()) {
        "A" {
            Write-Host ""
            Write-Host "Starting PAT-Based Setup..." -ForegroundColor Cyan
            Write-Host ""
            
            # Step 1: Create Service Connection with PAT
            New-ServiceConnection
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 1 Complete: Service Connection Created" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            
            # Step 2: Validate
            Write-Host "Validating service connection..." -ForegroundColor Cyan
            Test-ServiceConnection
            
            # Step 3: Update Pipeline YAML
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 2: Updating Pipeline YAML for GitHub Triggers" -ForegroundColor Cyan
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            Update-PipelineYAMLFiles
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "âœ“ SETUP COMPLETE!" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your setup is 100% complete. Next steps:" -ForegroundColor Cyan
            Write-Host "1. Commit your pipeline YAML changes: git add azure-pipelines.yml; git commit -m UpdatePipeline" -ForegroundColor White
            Write-Host "2. Push to GitHub: git push" -ForegroundColor White
            Write-Host "3. Test by pushing code to GitHub - your pipeline should trigger!" -ForegroundColor White
            Write-Host ""
        }
        "B" {
            Write-Host ""
            Write-Host "Starting OAuth Setup..." -ForegroundColor Cyan
            Write-Host ""
            
            # Step 1: Create Service Connection with OAuth
            New-ServiceConnectionOAuth
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 1 Complete: Service Connection Created" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            
            # Step 2: Validate
            Write-Host "Validating service connection..." -ForegroundColor Cyan
            Test-ServiceConnection
            
            # Step 3: Update Pipeline YAML
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 2: Updating Pipeline YAML for GitHub Triggers" -ForegroundColor Cyan
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            Update-PipelineYAMLFiles
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "âœ“ SETUP COMPLETE!" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your setup is 100% complete. Next steps:" -ForegroundColor Cyan
            Write-Host "1. Commit your pipeline YAML changes: git add azure-pipelines.yml; git commit -m 'Update pipeline for GitHub'" -ForegroundColor White
            Write-Host "2. Push to GitHub: git push" -ForegroundColor White
            Write-Host "3. Test by pushing code to GitHub - your pipeline should trigger!" -ForegroundColor White
            Write-Host "4. Webhooks are OAuth-based, so no token expiration issues!" -ForegroundColor Green
            Write-Host ""
        }
        "C" {
            Write-Host ""
            Write-Host "Starting Manual Service Connection Setup..." -ForegroundColor Cyan
            Write-Host ""
            
            # Step 1: Create Webhook Only
            Create-WebhookOnlyForExisting
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 1 Complete: Webhooks Created" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            
            # Step 2: Validate
            Write-Host "Validating service connection..." -ForegroundColor Cyan
            Test-ServiceConnection
            
            # Step 3: Update Pipeline YAML
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host "Step 2: Updating Pipeline YAML for GitHub Triggers" -ForegroundColor Cyan
            Write-Host "========================================================" -ForegroundColor Cyan
            Write-Host ""
            Update-PipelineYAMLFiles
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "âœ“ SETUP COMPLETE!" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your setup is 100% complete. Next steps:" -ForegroundColor Cyan
            Write-Host "1. Commit your pipeline YAML changes: git add azure-pipelines.yml; git commit -m UpdatePipeline" -ForegroundColor White
            Write-Host "2. Push to GitHub: git push" -ForegroundColor White
            Write-Host "3. Test by pushing code to GitHub - your pipeline should trigger!" -ForegroundColor White
            Write-Host "4. Webhooks are OAuth-based, so no token expiration issues!" -ForegroundColor Green
            Write-Host ""
        }
        default {
            Write-Host "Invalid option. Please select A, B, or C." -ForegroundColor Red
        }
    }
}

function Get-ProjectId {
    param(
