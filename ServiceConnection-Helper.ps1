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
    Write-Host "1. Create Service Connection from CSV" -ForegroundColor Yellow
    Write-Host "2. Validate Service Connection" -ForegroundColor Yellow
    Write-Host "3. Test GitHub Webhook" -ForegroundColor Yellow
    Write-Host "4. View Service Connections" -ForegroundColor Yellow
    Write-Host "5. View CSV Data" -ForegroundColor Yellow
    Write-Host "6. Manage Authentication (Add/Remove PATs)" -ForegroundColor Yellow
    Write-Host "7. Exit" -ForegroundColor Yellow
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
    Write-Host "This session will need PATs for creating and validating service connections." -ForegroundColor Yellow
    Write-Host ""
    
    $providePATs = Read-Host "Do you want to provide PATs now? (yes/no)"
    
    if ($providePATs -eq "yes" -or $providePATs -eq "y") {
        Write-Host ""
        Write-Host "Provide your credentials (they will remain in memory for this session only):" -ForegroundColor Cyan
        Write-Host ""
        
        $provideGitHub = Read-Host "Provide GitHub PAT? (yes/no)"
        if ($provideGitHub -eq "yes" -or $provideGitHub -eq "y") {
            $Global:GitHubPAT = Get-SecurePAT "GitHub PAT"
            Write-Host "[OK] GitHub PAT stored in session" -ForegroundColor Green
        }
        
        $provideADO = Read-Host "Provide Azure DevOps PAT? (yes/no)"
        if ($provideADO -eq "yes" -or $provideADO -eq "y") {
            $Global:AzureDevOpsPAT = Get-SecurePAT "Azure DevOps PAT"
            Write-Host "[OK] Azure DevOps PAT stored in session" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipping PAT setup. You can add them later from the menu." -ForegroundColor Yellow
    }
    
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

function New-ServiceConnection {
    Write-Host ""
    Write-Host "Creating Service Connection..." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    
    if (-not $Global:GitHubPAT -or -not $Global:AzureDevOpsPAT) {
        Write-Host "ERROR: Both GitHub PAT and Azure DevOps PAT are required!" -ForegroundColor Red
        Write-Host "Please add them in the Authentication menu first." -ForegroundColor Yellow
        return
    }
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    if ($data -is [System.Array]) {
        $connection = $data[0]
    } else {
        $connection = $data
    }
    
    Write-Host "Organization: $($connection.Organization)" -ForegroundColor Yellow
    Write-Host "Project: $($connection.ProjectName)" -ForegroundColor Yellow
    Write-Host "Repository: $($connection.RepositoryName)" -ForegroundColor Yellow
    Write-Host "Service Connection Name: $($connection.ServiceConnectionName)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Credentials loaded from session" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Log in to Azure DevOps: https://dev.azure.com/$($connection.Organization)/$($connection.ProjectName)" -ForegroundColor White
    Write-Host "2. Go to Project Settings > Service Connections" -ForegroundColor White
    Write-Host "3. Click 'New service connection' > GitHub" -ForegroundColor White
    Write-Host "4. Select 'Personal access token (PAT)'" -ForegroundColor White
    Write-Host "5. Fill in your GitHub PAT and service connection name: $($connection.ServiceConnectionName)" -ForegroundColor White
    Write-Host "6. Click 'Save'" -ForegroundColor White
    Write-Host ""
}

function Test-ServiceConnection {
    Write-Host ""
    Write-Host "Testing Service Connection..." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    
    if (-not $Global:AzureDevOpsPAT) {
        Write-Host "WARNING: Azure DevOps PAT not provided" -ForegroundColor Yellow
        Write-Host "You may not be able to query service connections" -ForegroundColor Yellow
    }
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    if ($data -is [System.Array]) {
        $connection = $data[0]
    } else {
        $connection = $data
    }
    
    $org = Read-Host "Enter Organization (or press Enter for '$($connection.Organization)')"
    if ([string]::IsNullOrEmpty($org)) { $org = $connection.Organization }
    
    $project = Read-Host "Enter Project (or press Enter for '$($connection.ProjectName)')"
    if ([string]::IsNullOrEmpty($project)) { $project = $connection.ProjectName }
    
    $scName = Read-Host "Enter Service Connection Name (or press Enter for '$($connection.ServiceConnectionName)')"
    if ([string]::IsNullOrEmpty($scName)) { $scName = $connection.ServiceConnectionName }
    
    Write-Host ""
    Write-Host "Test Command:" -ForegroundColor Yellow
    Write-Host "az devops service-endpoint list --organization https://dev.azure.com/$org --project $project --query ""[?name=='$scName']"" -o json" -ForegroundColor White
    Write-Host ""
    Write-Host "Run this command in Azure CLI to verify the service connection exists" -ForegroundColor Green
    Write-Host ""
}

function Test-Webhook {
    Write-Host ""
    Write-Host "GitHub Webhook Information:" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    
    if (-not $Global:GitHubPAT) {
        Write-Host "WARNING: GitHub PAT not provided" -ForegroundColor Yellow
        Write-Host "You may not be able to view webhook details" -ForegroundColor Yellow
    }
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    if ($data -is [System.Array]) {
        $connection = $data[0]
    } else {
        $connection = $data
    }
    
    Write-Host ""
    Write-Host "To verify webhook was created:" -ForegroundColor Yellow
    Write-Host "1. Go to GitHub: https://github.com/$($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor White
    Write-Host "2. Settings > Webhooks" -ForegroundColor White
    Write-Host "3. Look for webhook pointing to: dev.azure.com" -ForegroundColor White
    Write-Host "4. Click it and scroll to Recent Deliveries" -ForegroundColor White
    Write-Host "5. Check for successful deliveries (green checkmarks)" -ForegroundColor White
    Write-Host ""
}

function View-ServiceConnections {
    Write-Host ""
    Write-Host "Viewing Service Connections in Azure DevOps..." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    if ($data -is [System.Array]) {
        $connection = $data[0]
    } else {
        $connection = $data
    }
    
    Write-Host ""
    Write-Host "Open this URL in your browser:" -ForegroundColor Yellow
    Write-Host "https://dev.azure.com/$($connection.Organization)/$($connection.ProjectName)/_settings/adminservices" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use Azure CLI:" -ForegroundColor Yellow
    Write-Host "az devops service-endpoint list --organization https://dev.azure.com/$($connection.Organization) --project $($connection.ProjectName)" -ForegroundColor White
    Write-Host ""
}

# Main execution
if ($Action -eq "menu") {
    Initialize-Session
    
    do {
        Show-Menu
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            "1" { New-ServiceConnection; Read-Host "Press Enter to continue" }
            "2" { Test-ServiceConnection; Read-Host "Press Enter to continue" }
            "3" { Test-Webhook; Read-Host "Press Enter to continue" }
            "4" { View-ServiceConnections; Read-Host "Press Enter to continue" }
            "5" { Show-CSVData; Read-Host "Press Enter to continue" }
            "6" { Manage-Authentication }
            "7" { exit }
            default { Write-Host "Invalid option" -ForegroundColor Red; Read-Host "Press Enter to continue" }
        }
    } while ($true)
}
