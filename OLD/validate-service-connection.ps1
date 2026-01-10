param(
    [Parameter(Mandatory=$false)]
    [string]$Organization,
    [Parameter(Mandatory=$false)]
    [string]$Project,
    [Parameter(Mandatory=$false)]
    [string]$ServiceConnectionName = "github-service-connection"
)

# Function to validate a single organization/project/service connection
function Validate-ServiceConnection {
    param(
        [string]$Org,
        [string]$Proj,
        [string]$ServiceConnectionName
    )
    
    $result = @{
        Organization = $Org
        Project = $Proj
        ServiceConnection = $ServiceConnectionName
        Status = "UNKNOWN"
        Message = ""
        Details = @()
    }
    
    try {
        # 1. Check organization accessible
        $orgUrl = "https://dev.azure.com/$Org"
        
        try {
            $testOrgOutput = az devops project list --organization $orgUrl --output json 2>&1
            if ($testOrgOutput -match "ERROR" -or $testOrgOutput -match "error" -or $null -eq $testOrgOutput) {
                $result.Status = "FAILED"
                $result.Message = "Cannot access organization - check Azure DevOps PAT or organization name"
                return $result
            }
            $testOrg = $testOrgOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($null -ne $testOrg.value) {
                $testOrg = $testOrg.value
            }
        } catch {
            $result.Status = "FAILED"
            $result.Message = "Authentication failed - check Azure DevOps PAT token"
            return $result
        }
        
        if ($null -eq $testOrg) {
            $result.Status = "FAILED"
            $result.Message = "Cannot access organization"
            return $result
        }
        
        # 2. Verify project exists
        $projectFound = $testOrg | Where-Object { $_.name -eq $Proj } | Select-Object -First 1
        if ($null -eq $projectFound) {
            $result.Status = "FAILED"
            $result.Message = "Project not found in organization"
            return $result
        }
        
        # 3. List service connections in project
        $cmd = "az devops service-endpoint list --organization $orgUrl --project `"$Proj`" --output json"
        $connOutput = Invoke-Expression $cmd -ErrorAction SilentlyContinue 2>&1
        
        if ($connOutput -match "ERROR" -or $connOutput -match "error") {
            $result.Status = "FAILED"
            $result.Message = "Cannot list service connections - check project permissions"
            return $result
        }
        
        $connections = $connOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($null -eq $connections) {
            $result.Status = "FAILED"
            $result.Message = "Cannot list service connections (no permissions or project error)"
            return $result
        }
        
        # 4. Find the service connection
        $sc = $connections | Where-Object { $_.name -eq $ServiceConnectionName } | Select-Object -First 1
        
        if ($null -eq $sc) {
            $result.Status = "FAILED"
            $result.Message = "Service connection '$ServiceConnectionName' not found"
            if ($connections.Count -gt 0) {
                $result.Details = ($connections | Select-Object -ExpandProperty name)
                $result.Message += " - Available connections:"
            }
            return $result
        }
        
        # 5. Connection found and accessible
        $result.Status = "SUCCESS"
        $result.Message = "Service connection found and accessible"
        $result.Details = @(
            "Name: $($sc.name)",
            "Type: $($sc.type)",
            "URL: $($sc.url)"
        )
        return $result
        
    } catch {
        $result.Status = "ERROR"
        $result.Message = $_
        return $result
    }
}

# Main script
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Service Connection Batch Validator" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ALWAYS ask for Azure DevOps PAT if not provided via parameters
if ([string]::IsNullOrEmpty($Organization)) {
    # Interactive mode - ALWAYS get Azure DevOps PAT first
    Write-Host "STEP 1: Provide Azure DevOps PAT" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Azure DevOps PAT:" -ForegroundColor Cyan
    Write-Host "(Get from: https://dev.azure.com/git-AzDo/_usersSettings/tokens)" -ForegroundColor Gray
    $adoPat = Read-Host "Enter Azure DevOps PAT" -AsSecureString
    $adoPat = [System.Net.NetworkCredential]::new('', $adoPat).Password
    $env:AZURE_DEVOPS_EXT_PAT = $adoPat
    
    Write-Host ""
    Write-Host "STEP 2: Enter organization and project" -ForegroundColor Yellow
    Write-Host ""
    $Organization = Read-Host "Organization name (e.g., git-AzDo)"
    $Project = Read-Host "Project name (e.g., DotNet-GHAS)"
    $connName = Read-Host "Service connection name (e.g., github-service-connection)"
    if ([string]::IsNullOrEmpty($connName)) { 
        $ServiceConnectionName = "github-service-connection" 
    } else {
        $ServiceConnectionName = $connName
    }
} else {
    # Parameter mode - check environment PAT
    $adoPat = $env:ADO_PAT
    if ([string]::IsNullOrEmpty($adoPat)) {
        Write-Host "ERROR: Azure DevOps PAT not found in environment variable" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please run: .\set-secure-credentials.ps1" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or run in interactive mode:" -ForegroundColor Yellow
        Write-Host "  .\validate-service-connection.ps1" -ForegroundColor Cyan
        exit 1
    }
    $env:AZURE_DEVOPS_EXT_PAT = $adoPat
}

Write-Host ""
Write-Host "Validating: $Organization/$Project" -ForegroundColor Cyan
Write-Host ""

$result = Validate-ServiceConnection -Org $Organization -Proj $Project -ServiceConnectionName $ServiceConnectionName

switch ($result.Status) {
    "SUCCESS" {
        Write-Host "OK - SUCCESS" -ForegroundColor Green
        Write-Host "  $($result.Message)" -ForegroundColor Green
        if ($result.Details.Count -gt 0) {
            Write-Host ""
            foreach ($detail in $result.Details) {
                Write-Host "  $detail" -ForegroundColor Gray
            }
        }
    }
    "INCOMPLETE" {
        Write-Host "WARN - INCOMPLETE" -ForegroundColor Yellow
        Write-Host "  $($result.Message)" -ForegroundColor Yellow
        if ($result.Details.Count -gt 0) {
            Write-Host ""
            Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
            foreach ($detail in $result.Details) {
                Write-Host "  $detail" -ForegroundColor Cyan
            }
        }
    }
    "MISSING" {
        Write-Host "MISSING" -ForegroundColor Yellow
        Write-Host "  $($result.Message)" -ForegroundColor Yellow
        if ($result.Details.Count -gt 0) {
            Write-Host "  Available connections:" -ForegroundColor Cyan
            foreach ($detail in $result.Details) {
                Write-Host "    - $detail" -ForegroundColor Gray
            }
        }
    }
    "FAILED" {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Host "  $($result.Message)" -ForegroundColor Red
    }
    default {
        Write-Host "ERROR" -ForegroundColor Red
        Write-Host "  $($result.Message)" -ForegroundColor Red
    }
}

Write-Host ""
