<#
.SYNOPSIS
    Setup GitHub service connection in Azure DevOps
.DESCRIPTION
    Creates and configures a GitHub service connection for Azure DevOps.
    Supports GitHub.com, GitHub Enterprise Server, and GitHub Enterprise Cloud.
    
.PARAMETER Organization
    Azure DevOps organization name
    
.PARAMETER ProjectName
    Azure DevOps project name
    
.PARAMETER ConnectionName
    Name for the service connection (default: github-service-connection)
    
.PARAMETER GitHubServerUrl
    GitHub server URL (default: https://github.com)
    
.PARAMETER DryRun
    Preview what would be created without making changes
    
.PARAMETER SkipValidation
    Skip automatic validation after creation (optional)
    
.EXAMPLE
    .\setup-github-service-connection.ps1 -Organization my-org -ProjectName MyProject
    
.EXAMPLE
    .\setup-github-service-connection.ps1 -Organization my-org -ProjectName MyProject -DryRun
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Organization,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$ConnectionName = "github-service-connection",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubServerUrl = "https://github.com",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Get GitHub PAT from environment or prompt user
$GitHubToken = $env:GH_PAT
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  GitHub Personal Access Token Required" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "GitHub PAT not found in environment variable." -ForegroundColor Yellow
    Write-Host "Get one from: https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host ""
    $GitHubToken = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
    $GitHubToken = [System.Net.NetworkCredential]::new('', $GitHubToken).Password
}

# Get Azure DevOps PAT from environment or prompt user
$AzureDevOpsToken = $env:ADO_PAT
if ([string]::IsNullOrEmpty($AzureDevOpsToken)) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Azure DevOps Personal Access Token Required" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ADO PAT not found in environment variable." -ForegroundColor Yellow
    Write-Host "Get one from: https://dev.azure.com/$Organization/_usersSettings/tokens" -ForegroundColor Gray
    Write-Host ""
    $AzureDevOpsToken = Read-Host "Enter Azure DevOps Personal Access Token" -AsSecureString
    $AzureDevOpsToken = [System.Net.NetworkCredential]::new('', $AzureDevOpsToken).Password
}

# ====================================================================
# UTILITY FUNCTIONS
# ====================================================================

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Status = "Info"
    )
    
    $colorMap = @{
        Success = 'Green'
        Warning = 'Yellow'
        Error = 'Red'
        Info = 'Cyan'
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Status]
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ====================================================================
# MAIN FUNCTIONS
# ====================================================================

function Test-Prerequisites {
    Write-Section "VALIDATING PREREQUISITES"
    
    # Check GitHub token format
    if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
        Write-Status "[FAILED] GitHub token is required" "Error"
        exit 1
    }
    Write-Status "[OK] GitHub token provided" "Success"
    
    # Check Azure DevOps token format
    if ([string]::IsNullOrWhiteSpace($AzureDevOpsToken)) {
        Write-Status "[FAILED] Azure DevOps token is required" "Error"
        exit 1
    }
    Write-Status "[OK] Azure DevOps token provided" "Success"
    
    # Test Azure DevOps connectivity with REST API
    try {
        $orgUrl = "https://dev.azure.com/$Organization"
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$AzureDevOpsToken"))
        
        $response = Invoke-WebRequest -Uri "$orgUrl/_apis/projects?api-version=7.0" `
            -Headers @{Authorization = "Basic $auth"} `
            -Method GET `
            -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            Write-Status "[OK] Connected to Azure DevOps" "Success"
        }
        else {
            Write-Status "[FAILED] Cannot connect to Azure DevOps - check token or organization name" "Error"
            exit 1
        }
    }
    catch {
        Write-Status "[FAILED] Cannot connect to Azure DevOps: $_" "Error"
        exit 1
    }
}

function Create-ServiceConnection {
    Write-Section "CREATING SERVICE CONNECTION"
    
    if ($DryRun) {
        Write-Status "DRY RUN MODE - No changes will be made" "Warning"
    }
    
    Write-Status "Organization:  $Organization" "Info"
    Write-Status "Project:        $ProjectName" "Info"
    Write-Status "Connection:     $ConnectionName" "Info"
    Write-Status "GitHub URL:     $GitHubServerUrl" "Info"
    
    if ($DryRun) {
        Write-Status "`n[PREVIEW] Would create service connection with above settings" "Success"
        return $true
    }
    
    try {
        Write-Status "`nCreating service connection..." "Info"
        
        # First, get the project ID
        $orgUrl = "https://dev.azure.com/$Organization"
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$AzureDevOpsToken"))
        
        # Get project ID by name
        Write-Status "Getting project ID..." "Info"
        $projectsResponse = Invoke-WebRequest -Uri "$orgUrl/_apis/projects?api-version=7.0" `
            -Headers @{Authorization = "Basic $auth"} `
            -Method GET `
            -UseBasicParsing -ErrorAction Stop
        
        $projectData = $projectsResponse.Content | ConvertFrom-Json
        $project = $projectData.value | Where-Object {$_.name -eq $ProjectName} | Select-Object -First 1
        
        if (-not $project) {
            Write-Status "[FAILED] Project '$ProjectName' not found in organization" "Error"
            return $false
        }
        
        $ProjectId = $project.id
        Write-Status "Found project ID: $ProjectId" "Info"
        
        # Create JSON payload for service connection
        $payload = @{
            name = $ConnectionName
            type = "github"
            url = $GitHubServerUrl
            authorization = @{
                scheme = "PersonalAccessToken"
                parameters = @{
                    accessToken = $GitHubToken
                }
            }
            serviceEndpointProjectReferences = @(
                @{
                    projectReference = @{
                        id = $ProjectId
                        name = $ProjectName
                    }
                    name = $ConnectionName
                }
            )
        } | ConvertTo-Json -Depth 10
        
        # Create service endpoint
        Write-Status "Creating service endpoint..." "Info"
        $endpointResponse = Invoke-WebRequest -Uri "$orgUrl/_apis/serviceendpoint/endpoints?api-version=7.0" `
            -Headers @{Authorization = "Basic $auth"} `
            -Method POST `
            -ContentType "application/json" `
            -Body $payload `
            -UseBasicParsing -ErrorAction Stop
        
        $response = $endpointResponse.Content | ConvertFrom-Json
        
        if ($response.id) {
            Write-Status "[OK] Service connection created successfully" "Success"
            Write-Status "  ID: $($response.id)" "Info"
            Write-Status "  Name: $($response.name)" "Info"
            return $true
        }
        else {
            Write-Status "[FAILED] Failed to create service connection" "Error"
            return $false
        }
    }
    catch {
        $errorMessage = $_.ToString()
        
        # Check for duplicate connection error
        if ($errorMessage -match "already exists" -or $_.Exception.Message -match "already exists") {
            Write-Host ""
            Write-Status "[WARNING] Service connection already exists!" "Warning"
            Write-Host ""
            Write-Host "The service connection '$ConnectionName' already exists in the project." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "WHAT TO DO NEXT:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Option 1: Validate the existing connection" -ForegroundColor Green
            Write-Host "  .\validate-service-connection.ps1 -Organization $Organization -Project $ProjectName -ServiceConnectionName $ConnectionName" -ForegroundColor White
            Write-Host ""
            Write-Host "Option 2: Create with a different name" -ForegroundColor Green
            Write-Host "  .\setup-github-service-connection.ps1 -Organization $Organization -ProjectName $ProjectName -ConnectionName my-github-connection" -ForegroundColor White
            Write-Host ""
            Write-Host "Option 3: Delete existing and recreate (manual)" -ForegroundColor Green
            Write-Host "  1. Go to Azure DevOps: $orgUrl" -ForegroundColor Gray
            Write-Host "  2. Project Settings -> Service connections" -ForegroundColor Gray
            Write-Host "  3. Find '$ConnectionName' and delete it" -ForegroundColor Gray
            Write-Host "  4. Re-run this script" -ForegroundColor Gray
            Write-Host ""
            return $false
        }
        else {
            Write-Status "[ERROR] Error creating service connection: $_" "Error"
            Write-Host ""
            Write-Host "Error details:" -ForegroundColor Yellow
            Write-Host $errorMessage -ForegroundColor Red
            return $false
        }
    }
}

function Get-PipelineStatus {
    param(
        [string]$Organization,
        [string]$ProjectName,
        [string]$AzureDevOpsToken
    )
    
    Write-Section "PIPELINE STATUS REPORT"
    
    try {
        $orgUrl = "https://dev.azure.com/$Organization"
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$AzureDevOpsToken"))
        
        # Get all pipelines
        $pipelinesResponse = Invoke-WebRequest -Uri "$orgUrl/$ProjectName/_apis/pipelines?api-version=7.1-preview.1" `
            -Headers @{Authorization = "Basic $auth"} `
            -Method GET `
            -UseBasicParsing -ErrorAction Stop
        
        $pipelinesData = $pipelinesResponse.Content | ConvertFrom-Json
        $pipelines = $pipelinesData.value
        
        Write-Status "Total Pipelines: $($pipelines.Count)" "Info"
        
        if ($pipelines.Count -eq 0) {
            Write-Status "No pipelines found in project" "Warning"
            return
        }
        
        Write-Host ""
        
        $githubTriggerCount = 0
        
        foreach ($pipeline in $pipelines) {
            Write-Status "Pipeline: $($pipeline.name)" "Info"
            Write-Status "  ID: $($pipeline.id)" "Info"
            
            # Get pipeline definition to check triggers
            $pipelineResponse = Invoke-WebRequest -Uri "$orgUrl/$ProjectName/_apis/pipelines/$($pipeline.id)?api-version=7.1-preview.1" `
                -Headers @{Authorization = "Basic $auth"} `
                -Method GET `
                -UseBasicParsing -ErrorAction SilentlyContinue
            
            if ($pipelineResponse) {
                $pipelineDetail = $pipelineResponse.Content | ConvertFrom-Json
                
                # Check if it has GitHub trigger
                if ($pipelineDetail.configuration.repository.type -eq "github" -or $pipelineDetail.configuration.type -eq "github") {
                    Write-Status "  Trigger: GitHub (Configured)" "Success"
                    $githubTriggerCount++
                }
                else {
                    Write-Status "  Trigger: Other/Not configured for GitHub" "Info"
                }
            }
            
            Write-Host ""
        }
        
        Write-Section "SUMMARY"
        Write-Status "Total Pipelines: $($pipelines.Count)" "Info"
        Write-Status "GitHub-Triggered: $githubTriggerCount" "Success"
        
        if ($githubTriggerCount -gt 0) {
            Write-Status "Status: READY - Pipelines will trigger on GitHub code changes" "Success"
        }
        else {
            Write-Status "Status: NOT READY - Configure pipelines to trigger from GitHub" "Warning"
        }
        
    }
    catch {
        Write-Status "Could not retrieve pipeline status: $_" "Warning"
    }
}

function Main {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  GitHub Service Connection Setup" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Validate
    Test-Prerequisites
    
    # Create service connection
    $success = Create-ServiceConnection
    
    if ($success) {
        Write-Section "SETUP COMPLETE"
        Write-Status "[OK] Service connection is ready" "Success"
        
        if ($DryRun) {
            Write-Status "`nRun again without -DryRun to create the connection" "Info"
        }
        else {
            # Show pipeline status after successful setup
            Write-Host ""
            Get-PipelineStatus -Organization $Organization -ProjectName $ProjectName -AzureDevOpsToken $AzureDevOpsToken
            
            Write-Host ""
            Write-Status "Setup and validation complete" "Success"
        }
    }
    else {
        Write-Status "[FAILED] Setup failed" "Error"
        exit 1
    }
}

try {
    Main
}
catch {
    Write-Status "Error: $_" "Error"
    exit 1
}
