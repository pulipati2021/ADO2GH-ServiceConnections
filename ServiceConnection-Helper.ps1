# Azure DevOps GitHub Pipeline Setup - Version 4.0
# Clean, simple 4-step workflow
param([string]$Action = "start")

$ConfigFile = "SERVICE-CONNECTIONS.csv"
$LogFile = "pipeline-setup.log"
$AzDoUrl = "https://dev.azure.com"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Show-Menu {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "===== Azure DevOps GitHub Pipeline Setup v4.0 =====" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Step 1: Get PAT and List Projects" -ForegroundColor Green
    Write-Host "  [2] Step 2: Select Project and View Service Connections" -ForegroundColor Green
    Write-Host "  [3] Step 3: Configure Pipelines - Fill CSV" -ForegroundColor Green
    Write-Host "  [4] Step 4: Validate Webhooks in GitHub" -ForegroundColor Green
    Write-Host "  [5] Exit" -ForegroundColor Red
    Write-Host ""
}

function Step1-GetPAT {
    Write-Host "`nSTEP 1: Get PAT and List Projects" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
    
    $pat = Read-Host "Enter your Azure DevOps PAT"
    $org = Read-Host "Enter Azure DevOps Organization name"
    
    $global:AzDoPAT = $pat
    $global:AzDoOrg = $org
    
    $header = @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat")))"}
    
    try {
        $projectsUrl = "$AzDoUrl/$org/_apis/projects?api-version=7.0"
        $response = Invoke-RestMethod -Uri $projectsUrl -Headers $header -Method Get -ErrorAction Stop
        
        Write-Host "[OK] PAT validated!" -ForegroundColor Green
        Write-Log "PAT validated for org: $org"
        
        if ($response.value.Count -eq 0) {
            Write-Host "No projects found." -ForegroundColor Yellow
            return
        }
        
        Write-Host "Projects found: $($response.value.Count)" -ForegroundColor Green
        Write-Host ""
        
        $response.value | ForEach-Object { Write-Host "  - $($_.name)" }
        
        $global:Projects = $response.value
        
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR in Step 1: $($_.Exception.Message)"
    }
}

function Step2-SelectProject {
    Write-Host "`nSTEP 2: Select Project and View Service Connections" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $global:AzDoPAT) {
        Write-Host "Run Step 1 first!" -ForegroundColor Red
        return
    }
    
    if (-not $global:Projects) {
        Write-Host "No projects available." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Select a project:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $global:Projects.Count; $i++) {
        Write-Host "  [$($i+1)] $($global:Projects[$i].name)"
    }
    
    $choice = Read-Host "Select (1-$($global:Projects.Count))"
    $idx = [int]$choice - 1
    
    if ($idx -lt 0 -or $idx -ge $global:Projects.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }
    
    $project = $global:Projects[$idx]
    $global:SelectedProject = $project
    
    Write-Host ""
    Write-Host "Selected: $($project.name)" -ForegroundColor Green
    Write-Host ""
    
    $header = @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$global:AzDoPAT")))"}
    
    try {
        $scUrl = "$AzDoUrl/$global:AzDoOrg/$($project.name)/_apis/serviceendpoint/endpoints?api-version=7.1"
        $scResponse = Invoke-RestMethod -Uri $scUrl -Headers $header -Method Get -ErrorAction Stop
        
        if ($scResponse.value.Count -eq 0) {
            Write-Host "No service connections in this project." -ForegroundColor Yellow
            return
        }
        
        Write-Host "Service Connections:" -ForegroundColor Cyan
        Write-Host ""
        $scResponse.value | ForEach-Object { Write-Host "  - $($_.name) (Type: $($_.type))" }
        
        $global:ServiceConnections = $scResponse.value
        
        Write-Log "Found $($scResponse.value.Count) service connections in project: $($project.name)"
        
    } catch {
        Write-Host "[ERROR] Error fetching service connections: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR in Step 2: $($_.Exception.Message)"
    }
}

function Step3-ConfigurePipelines {
    Write-Host "`nSTEP 3: Configure Pipelines - Fill CSV" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $global:SelectedProject) {
        Write-Host "Run Step 2 first!" -ForegroundColor Red
        return
    }
    
    if (-not $global:ServiceConnections) {
        Write-Host "No service connections available." -ForegroundColor Red
        return
    }
    
    $projectName = $global:SelectedProject.name
    Write-Host "Project: $projectName" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Select Service Connection:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $global:ServiceConnections.Count; $i++) {
        Write-Host "  [$($i+1)] $($global:ServiceConnections[$i].name)"
    }
    
    $scChoice = Read-Host "Select (1-$($global:ServiceConnections.Count))"
    $scIdx = [int]$scChoice - 1
    
    if ($scIdx -lt 0 -or $scIdx -ge $global:ServiceConnections.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }
    
    $scName = $global:ServiceConnections[$scIdx].name
    Write-Host ""
    Write-Host "Selected Service Connection: $scName" -ForegroundColor Green
    Write-Host ""
    
    $addMore = "yes"
    $pipelineCount = 0
    
    while ($addMore.ToLower() -eq "yes") {
        $pipelineCount++
        Write-Host "Pipeline #$($pipelineCount):" -ForegroundColor Yellow
        
        $gitOrg = Read-Host "  GitHub Organization/Owner"
        $gitRepo = Read-Host "  GitHub Repository Name"
        $pipelineName = Read-Host "  Pipeline Name"
        $yamlFile = Read-Host "  Pipeline YAML file (default: azure-pipelines.yml)"
        if ([string]::IsNullOrEmpty($yamlFile)) { $yamlFile = "azure-pipelines.yml" }
        
        $row = "$global:AzDoOrg,$projectName,$scName,$gitRepo,$gitOrg,$yamlFile,Pending,"
        
        # Create CSV header if not exists
        if (-not (Test-Path $ConfigFile)) {
            $header = "Organization,ProjectName,ServiceConnectionName,RepositoryName,RepositoryOwner,PipelineFile,Status,Notes"
            Add-Content -Path $ConfigFile -Value $header
        }
        
        Add-Content -Path $ConfigFile -Value $row
        Write-Host "[OK] Added to CSV" -ForegroundColor Green
        
        Write-Log "Added pipeline: $pipelineName ($gitOrg/$gitRepo)"
        
        $addMore = Read-Host "Add more pipelines? (yes/no)"
    }
    
    Write-Host ""
    Write-Host "CSV File:" -ForegroundColor Green
    Get-Content $ConfigFile | Select-Object -First 5
}

function Step4-ValidateWebhooks {
    Write-Host "`nSTEP 4: Validate Webhooks in GitHub" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "CSV file not found." -ForegroundColor Red
        return
    }
    
    $lines = @(Get-Content $ConfigFile)
    
    if ($lines.Count -lt 2) {
        Write-Host "No pipelines in CSV." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Checking webhooks in GitHub repositories:" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ([string]::IsNullOrEmpty($lines[$i])) { continue }
        
        $parts = $lines[$i] -split ','
        $owner = $parts[4]
        $repo = $parts[3]
        
        $hookUrl = "https://github.com/$owner/$repo/settings/hooks"
        
        Write-Host "Repository: $owner/$repo" -ForegroundColor Cyan
        Write-Host "  Check at: $hookUrl" -ForegroundColor Yellow
        Write-Host "  Look for webhook from dev.azure.com" -ForegroundColor White
        
        $verified = Read-Host "  Webhook verified? (yes/no)"
        
        if ($verified.ToLower() -eq "yes") {
            Write-Host "[OK] Verified" -ForegroundColor Green
            Write-Log "Webhook verified: $owner/$repo"
        } else {
            Write-Host "[NO] Not verified" -ForegroundColor Red
            Write-Log "Webhook NOT verified: $owner/$repo"
        }
        
        Write-Host ""
    }
}

# Main Loop
if ($Action -eq "start") {
    Write-Log "Session started"
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select (1-5)"
        
        switch ($choice) {
            "1" { Step1-GetPAT }
            "2" { Step2-SelectProject }
            "3" { Step3-ConfigurePipelines }
            "4" { Step4-ValidateWebhooks }
            "5" { 
                Write-Log "Session ended"
                exit 
            }
            default { Write-Host "Invalid choice." -ForegroundColor Red }
        }
        
        Read-Host "Press Enter to continue"
    }
}
