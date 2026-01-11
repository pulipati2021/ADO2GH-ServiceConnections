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
    
    # Handle both single connection and array of connections
    if ($data -is [System.Array]) {
        $connections = $data
    } else {
        $connections = @($data)
    }
    
    # If multiple connections, ask which one to create
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple service connections to create:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].ServiceConnectionName) in $($connections[$i].Organization)/$($connections[$i].ProjectName)"
        }
        Write-Host ""
        
        $selection = Read-Host "Select connection to create (1-$($connections.Count))"
        $index = [int]$selection - 1
        
        if ($index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }
        $connection = $connections[$index]
    } else {
        $connection = $connections[0]
    }
    
    Write-Host ""
    Write-Host "Creating: $($connection.ServiceConnectionName)" -ForegroundColor Yellow
    Write-Host "Organization: $($connection.Organization)" -ForegroundColor White
    Write-Host "Project: $($connection.ProjectName)" -ForegroundColor White
    Write-Host "Repository: $($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor White
    Write-Host ""
    
    $confirm = Read-Host "Proceed with creation? (yes/no)"
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Create the service connection using Azure DevOps REST API
    $orgUrl = "https://dev.azure.com/$($connection.Organization)"
    $projectName = $connection.ProjectName
    $scName = $connection.ServiceConnectionName
    $githubPat = $Global:GitHubPAT
    $adoPat = $Global:AzureDevOpsPAT
    
    # Prepare authentication header for Azure DevOps API
    $authHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat")) }
    
    # Service connection payload for GitHub
    $serviceConnectionPayload = @{
        name = $scName
        type = "github"
        url = "https://api.github.com"
        authorization = @{
            scheme = "PersonalAccessToken"
            parameters = @{
                accessToken = $githubPat
            }
        }
        description = "Service connection for $($connection.RepositoryOwner)/$($connection.RepositoryName)"
        operationStatus = $null
    } | ConvertTo-Json
    
    Write-Host "Sending request to Azure DevOps API..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$orgUrl/_apis/serviceendpoint/endpoints?api-version=6.0" `
            -Method Post `
            -Headers $authHeader `
            -ContentType "application/json" `
            -Body $serviceConnectionPayload `
            -ErrorAction Stop
        
        if ($response.id) {
            Write-Host ""
            Write-Host "[OK] Service connection created successfully!" -ForegroundColor Green
            Write-Host "ID: $($response.id)" -ForegroundColor White
            Write-Host "Name: $($response.name)" -ForegroundColor White
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "1. Go to: $orgUrl/$projectName/_settings/adminservices" -ForegroundColor White
            Write-Host "2. Verify the service connection appears in the list" -ForegroundColor White
            Write-Host "3. Update your pipeline YAML to use this service connection" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "[ERROR] Service connection creation failed" -ForegroundColor Red
            Write-Host "Response: $response" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Failed to create service connection" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual alternative:" -ForegroundColor Yellow
        Write-Host "1. Go to: $orgUrl/$projectName/_settings/adminservices" -ForegroundColor White
        Write-Host "2. Click 'New service connection' > GitHub" -ForegroundColor White
        Write-Host "3. Select 'Personal access token (PAT)'" -ForegroundColor White
        Write-Host "4. Paste your GitHub PAT and name it: $scName" -ForegroundColor White
        Write-Host "5. Click 'Save'" -ForegroundColor White
    }
    
    Write-Host ""
}

function Test-ServiceConnection {
    Write-Host ""
    Write-Host "Testing Service Connection..." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    
    if (-not $Global:AzureDevOpsPAT) {
        Write-Host "WARNING: Azure DevOps PAT not provided" -ForegroundColor Yellow
        Write-Host "You will need to run commands manually" -ForegroundColor Yellow
    }
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    # Handle both single connection and array of connections
    if ($data -is [System.Array]) {
        $connections = $data
    } else {
        $connections = @($data)
    }
    
    # If multiple connections, ask which one to test
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple service connections found:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].ServiceConnectionName) ($($connections[$i].Organization)/$($connections[$i].ProjectName))"
        }
        Write-Host ""
        
        $selection = Read-Host "Select connection to test (1-$($connections.Count))"
        $index = [int]$selection - 1
        
        if ($index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }
        $connection = $connections[$index]
    } else {
        $connection = $connections[0]
    }
    
    Write-Host ""
    Write-Host "Testing: $($connection.ServiceConnectionName)" -ForegroundColor Yellow
    Write-Host "Organization: $($connection.Organization)" -ForegroundColor White
    Write-Host "Project: $($connection.ProjectName)" -ForegroundColor White
    Write-Host ""
    
    # If Azure CLI is available and PAT is provided, try to run the command
    if ($Global:AzureDevOpsPAT) {
        $cliAvailable = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
        
        if ($cliAvailable) {
            Write-Host "Running validation via Azure CLI..." -ForegroundColor Cyan
            Write-Host ""
            
            $env:AZURE_DEVOPS_EXT_PAT = $Global:AzureDevOpsPAT
            
            try {
                $result = az devops service-endpoint list `
                    --organization "https://dev.azure.com/$($connection.Organization)" `
                    --project "$($connection.ProjectName)" `
                    --query "[?name=='$($connection.ServiceConnectionName)']" `
                    -o json 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $endpoints = $result | ConvertFrom-Json
                    if ($endpoints.Count -gt 0) {
                        Write-Host "[OK] Service connection FOUND!" -ForegroundColor Green
                        Write-Host ""
                        $endpoints | Format-Table -Property @{Name="Name"; Expression={$_.name}}, @{Name="Type"; Expression={$_.type}}, @{Name="URL"; Expression={$_.url}} -AutoSize
                    } else {
                        Write-Host "[!] Service connection NOT FOUND" -ForegroundColor Yellow
                        Write-Host "Service connection '$($connection.ServiceConnectionName)' does not exist in the project" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "[ERROR] Azure CLI command failed" -ForegroundColor Red
                    Write-Host "Output: $result" -ForegroundColor Red
                }
            } catch {
                Write-Host "[ERROR] Exception occurred: $_" -ForegroundColor Red
            } finally {
                Remove-Item env:AZURE_DEVOPS_EXT_PAT -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "[!] Azure CLI not found. Install with: choco install azure-cli" -ForegroundColor Yellow
            Write-Host ""
            Display-TestCommand $connection
        }
    } else {
        Write-Host "Provide the test command to run manually:" -ForegroundColor Yellow
        Write-Host ""
        Display-TestCommand $connection
    }
    
    Write-Host ""
}

function Display-TestCommand {
    param([object]$connection)
    
    Write-Host "az devops service-endpoint list \" -ForegroundColor White
    Write-Host "  --organization https://dev.azure.com/$($connection.Organization) \" -ForegroundColor White
    Write-Host "  --project $($connection.ProjectName) \" -ForegroundColor White
    Write-Host "  --query ""[?name=='$($connection.ServiceConnectionName)']"" \" -ForegroundColor White
    Write-Host "  -o json" -ForegroundColor White
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
    
    # Handle both single connection and array of connections
    if ($data -is [System.Array]) {
        $connections = $data
    } else {
        $connections = @($data)
    }
    
    # If multiple connections, ask which one to check
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple repositories found:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].RepositoryOwner)/$($connections[$i].RepositoryName)"
        }
        Write-Host ""
        
        $selection = Read-Host "Select repository to check webhook (1-$($connections.Count))"
        $index = [int]$selection - 1
        
        if ($index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }
        $connection = $connections[$index]
    } else {
        $connection = $connections[0]
    }
    
    Write-Host ""
    Write-Host "Repository: $($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor Yellow
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
    
    # Handle both single connection and array of connections
    if ($data -is [System.Array]) {
        $connections = $data
    } else {
        $connections = @($data)
    }
    
    # If multiple connections, ask which project
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple projects found:" -ForegroundColor Yellow
        Write-Host ""
        
        $uniqueProjects = $connections | Select-Object -Property Organization, ProjectName -Unique
        
        for ($i = 0; $i -lt $uniqueProjects.Count; $i++) {
            Write-Host "$($i + 1). $($uniqueProjects[$i].Organization)/$($uniqueProjects[$i].ProjectName)"
        }
        Write-Host ""
        
        $selection = Read-Host "Select project to view (1-$($uniqueProjects.Count))"
        $index = [int]$selection - 1
        
        if ($index -lt 0 -or $index -ge $uniqueProjects.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }
        $selectedProject = $uniqueProjects[$index]
        $org = $selectedProject.Organization
        $project = $selectedProject.ProjectName
    } else {
        $connection = $connections[0]
        $org = $connection.Organization
        $project = $connection.ProjectName
    }
    
    Write-Host ""
    Write-Host "Azure DevOps Service Connections URL:" -ForegroundColor Yellow
    Write-Host "https://dev.azure.com/$org/$project/_settings/adminservices" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use Azure CLI:" -ForegroundColor Yellow
    Write-Host "az devops service-endpoint list --organization https://dev.azure.com/$org --project $project" -ForegroundColor White
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
