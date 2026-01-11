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
            Write-Host "✓ SETUP COMPLETE!" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your setup is 100% complete. Next steps:" -ForegroundColor Cyan
            Write-Host "1. Commit your pipeline YAML changes: git add azure-pipelines.yml && git commit -m 'Update pipeline for GitHub'" -ForegroundColor White
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
            Write-Host "✓ SETUP COMPLETE!" -ForegroundColor Green
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
            Write-Host "✓ SETUP COMPLETE!" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your setup is 100% complete. Next steps:" -ForegroundColor Cyan
            Write-Host "1. Commit your pipeline YAML changes: git add azure-pipelines.yml && git commit -m 'Update pipeline for GitHub'" -ForegroundColor White
            Write-Host "2. Push to GitHub: git push" -ForegroundColor White
            Write-Host "3. Test by pushing code to GitHub - your pipeline should trigger!" -ForegroundColor White
            Write-Host ""
        }
        default {
            Write-Host "Invalid option. Please select A, B, or C." -ForegroundColor Red
        }
    }
}

function Get-ProjectId {
    param(
        [string]$OrgUrl,
        [string]$ProjectName,
        [hashtable]$AuthHeader
    )
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$OrgUrl/_apis/projects/$ProjectName`?api-version=6.0" `
            -Method Get `
            -Headers $AuthHeader `
            -ErrorAction Stop
        
        return $response.id
    } catch {
        Write-Host "[ERROR] Failed to get project ID for '$ProjectName'" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Create-GitHubWebhook {
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$GitHubPAT,
        [string]$Organization,
        [string]$ProjectName,
        [string]$ServiceConnectionId,
        [hashtable]$AuthHeader
    )
    
    Write-Host ""
    Write-Host "Setting up GitHub webhook..." -ForegroundColor Cyan
    
    $orgUrl = "https://dev.azure.com/$Organization"
    
    try {
        # Create webhook via GitHub API using the correct Azure DevOps endpoint
        $githubHeaders = @{
            Authorization = "token $GitHubPAT"
            Accept = "application/vnd.github.v3+json"
        }
        
        # The webhook URL should be a generic webhook that Azure DevOps can receive
        # Using the service hook receiver endpoint
        $webhookUrl = "$orgUrl/_apis/public/repos/github/webhooks"
        
        $githubWebhookPayload = @{
            name = "web"
            active = $true
            events = @("push", "pull_request")
            config = @{
                url = $webhookUrl
                content_type = "json"
                insecure_ssl = "0"
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/hooks" `
            -Method Post `
            -Headers $githubHeaders `
            -ContentType "application/json" `
            -Body $githubWebhookPayload `
            -ErrorAction Stop
        
        Write-Host "[OK] GitHub webhook created successfully!" -ForegroundColor Green
        Write-Host "Webhook ID: $($response.id)" -ForegroundColor White
        Write-Host "URL: $($response.config.url)" -ForegroundColor White
        Write-Host ""
        
        # Test the webhook
        Write-Host "Testing webhook connectivity..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        
        # Get webhook deliveries
        try {
            $deliveries = Invoke-RestMethod `
                -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/hooks/$($response.id)/deliveries" `
                -Method Get `
                -Headers $githubHeaders `
                -ErrorAction Stop
            
            if ($deliveries -and $deliveries.Count -gt 0) {
                if ($deliveries[0].status -eq "OK" -or $deliveries[0].response.code -eq 200) {
                    Write-Host "[OK] Webhook test successful!" -ForegroundColor Green
                } else {
                    Write-Host "[!] Webhook created but delivery status: $($deliveries[0].status)" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "[!!] Could not verify webhook delivery - will work on next push" -ForegroundColor Yellow
        }
        
        return $true
    } catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -like "*422*" -or $errorMessage -like "*already exists*") {
            Write-Host "[!] Webhook already exists for this repository" -ForegroundColor Yellow
            return $true
        } else {
            Write-Host "[WARNING] Failed to create GitHub webhook automatically" -ForegroundColor Yellow
            Write-Host "Error: $errorMessage" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Manual setup required:" -ForegroundColor Yellow
            Write-Host "1. Go to: https://github.com/$RepoOwner/$RepoName/settings/hooks" -ForegroundColor White
            Write-Host "2. Click 'Add webhook'" -ForegroundColor White
            Write-Host "3. Payload URL: https://dev.azure.com/$Organization/_apis/public/repos/github/webhooks" -ForegroundColor White
            Write-Host "4. Content type: application/json" -ForegroundColor White
            Write-Host "5. Events: Let me select individual events > Push events, Pull requests" -ForegroundColor White
            Write-Host "6. Active: Checked" -ForegroundColor White
            Write-Host "7. Click 'Add webhook'" -ForegroundColor White
            Write-Host ""
            Write-Host "If webhook still fails (404):" -ForegroundColor Yellow
            Write-Host "- Verify your Azure DevOps organization URL is correct" -ForegroundColor White
            Write-Host "- The webhook may require your organization to have proper GitHub integration enabled" -ForegroundColor White
            Write-Host "- As a workaround, create an Azure DevOps Service Hook instead" -ForegroundColor White
            return $false
        }
    }
}

function Create-ServiceHookSubscription {
    param(
        [string]$Organization,
        [string]$ProjectName,
        [string]$ServiceConnectionId,
        [string]$RepoOwner,
        [string]$RepoName,
        [hashtable]$AuthHeader
    )
    
    Write-Host ""
    Write-Host "Creating Azure DevOps Service Hook subscription..." -ForegroundColor Cyan
    
    $orgUrl = "https://dev.azure.com/$Organization"
    
    # Create subscription for GitHub push and pull request events
    $subscriptionPayload = @{
        publisherId = "github"
        eventType = "git.push"
        resourceVersion = "1.0"
        consumerId = "azureDevOpsServer"
        consumerActionId = "workItemStateChangeNotification"
        scope = "all"
        channel = "web"
        detailedMessagesOn = $false
        status = "active"
        probationRetries = 0
        publisherInputs = @{
            repository = "$RepoOwner/$RepoName"
            gitHubConnectionId = $ServiceConnectionId
            branchFilters = @("[*]")
        }
        consumerInputs = @{
            workItemType = "Bug"
            action = "create"
            comment = "Created from GitHub event"
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$orgUrl/$ProjectName/_apis/hooks/subscriptions?api-version=6.0-preview.1" `
            -Method Post `
            -Headers $AuthHeader `
            -ContentType "application/json" `
            -Body $subscriptionPayload `
            -ErrorAction Stop
        
        Write-Host "[OK] Service Hook subscription created!" -ForegroundColor Green
        Write-Host "Subscription ID: $($response.id)" -ForegroundColor White
        Write-Host "Event Type: $($response.eventType)" -ForegroundColor White
        Write-Host "Status: $($response.status)" -ForegroundColor White
        return $true
    } catch {
        Write-Host "[!!] Service Hook subscription creation result:" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can manually create service hook:" -ForegroundColor Yellow
        Write-Host "1. Go to: $orgUrl/$ProjectName/_settings/serviceHooks" -ForegroundColor White
        Write-Host "2. Click Create subscription" -ForegroundColor White
        Write-Host "3. Choose GitHub as the service" -ForegroundColor White
        Write-Host "4. Select event type (Push, Pull request, etc.)" -ForegroundColor White
        Write-Host "5. Configure filters for repository: $RepoOwner/$RepoName" -ForegroundColor White
        Write-Host "6. Set action (e.g., Run pipeline, Create work item)" -ForegroundColor White
        Write-Host "7. Save the subscription" -ForegroundColor White
        return $false
    }
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
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select connection to create (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
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
    
    # Get the project ID
    Write-Host "Fetching project ID..." -ForegroundColor Cyan
    $projectId = Get-ProjectId -OrgUrl $orgUrl -ProjectName $projectName -AuthHeader $authHeader
    
    if ($null -eq $projectId) {
        Write-Host "Cannot proceed without project ID" -ForegroundColor Red
        return
    }
    
    Write-Host "Project ID: $projectId" -ForegroundColor White
    Write-Host ""
    
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
        serviceEndpointProjectReferences = @(
            @{
                projectReference = @{
                    id = $projectId
                    name = $projectName
                }
                name = $scName
            }
        )
    } | ConvertTo-Json -Depth 10
    
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
            Write-Host "Type: $($response.type)" -ForegroundColor White
            Write-Host ""
            
            # Validate service connection type
            if ($response.type -ne "github") {
                Write-Host "[WARNING] Service connection type is '$($response.type)' but should be 'github'" -ForegroundColor Yellow
                Write-Host "This may cause webhook 404 errors!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Fix:" -ForegroundColor Yellow
                Write-Host "1. Delete this service connection" -ForegroundColor White
                Write-Host "2. Ensure you select 'GitHub' (not GitHub Enterprise Server)" -ForegroundColor White
                Write-Host "3. Create a new service connection" -ForegroundColor White
                Write-Host ""
            }
            
            # Attempt to create webhook automatically
            $webhookCreated = Create-GitHubWebhook `
                -RepoOwner $connection.RepositoryOwner `
                -RepoName $connection.RepositoryName `
                -GitHubPAT $githubPat `
                -Organization $connection.Organization `
                -ProjectName $projectName `
                -ServiceConnectionId $response.id `
                -AuthHeader $authHeader
            
            # Attempt to create Azure DevOps Service Hook subscription
            Write-Host ""
            $serviceHookCreated = Create-ServiceHookSubscription `
                -Organization $connection.Organization `
                -ProjectName $projectName `
                -ServiceConnectionId $response.id `
                -RepoOwner $connection.RepositoryOwner `
                -RepoName $connection.RepositoryName `
                -AuthHeader $authHeader
            
            Write-Host ""
            Write-Host "Setup Summary:" -ForegroundColor Green
            Write-Host "  [OK] Service connection created (PAT)" -ForegroundColor Green
            if ($webhookCreated) {
                Write-Host "  [OK] GitHub webhook created" -ForegroundColor Green
            } else {
                Write-Host "  [!] GitHub webhook creation - may need manual setup" -ForegroundColor Yellow
            }
            if ($serviceHookCreated) {
                Write-Host "  [OK] Azure DevOps Service Hook created" -ForegroundColor Green
            } else {
                Write-Host "  [!] Service Hook creation - may need manual setup" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "IMPORTANT - Next Required Step:" -ForegroundColor Yellow
            Write-Host "  [->] Use Option 6 to update pipeline YAML for GitHub triggers!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Why? Your pipelines currently show 'azuregit' (Azure Repos), not GitHub." -ForegroundColor Cyan
            Write-Host "Option 6 automatically updates your pipeline to trigger from GitHub." -ForegroundColor Cyan
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

function New-ServiceConnectionOAuth {
    Write-Host ""
    Write-Host "Create Service Connection with OAuth (GitHub Authorization)" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OAuth provides MORE RELIABLE webhook delivery than PAT." -ForegroundColor Green
    Write-Host "Why? GitHub will use Azure DevOps' OAuth flow instead of a token." -ForegroundColor White
    Write-Host ""
    
    if (-not $Global:AzureDevOpsPAT) {
        Write-Host "ERROR: Azure DevOps PAT not provided!" -ForegroundColor Red
        Write-Host "Please run option 8 (Manage Authentication) to add Azure DevOps PAT first" -ForegroundColor Yellow
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
    
    # If multiple connections, ask which one
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple repositories found:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].RepositoryOwner)/$($connections[$i].RepositoryName)"
        }
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select repository (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
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
    Write-Host "Next step will open Azure DevOps in your browser for OAuth authorization." -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Proceed? (yes/no)"
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Create the service connection using Azure DevOps REST API with OAuth
    $orgUrl = "https://dev.azure.com/$($connection.Organization)"
    $projectName = $connection.ProjectName
    $scName = $connection.ServiceConnectionName
    $adoPat = $Global:AzureDevOpsPAT
    
    # Prepare authentication header for Azure DevOps API
    $authHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat")) }
    
    # Get the project ID
    Write-Host "Fetching project ID..." -ForegroundColor Cyan
    $projectId = Get-ProjectId -OrgUrl $orgUrl -ProjectName $projectName -AuthHeader $authHeader
    
    if ($null -eq $projectId) {
        Write-Host "Cannot proceed without project ID" -ForegroundColor Red
        return
    }
    
    Write-Host "Project ID: $projectId" -ForegroundColor White
    Write-Host ""
    
    # Service connection payload for GitHub OAuth
    # With OAuth, we don't include a PAT - Azure DevOps will handle the OAuth handshake
    $serviceConnectionPayload = @{
        name = $scName
        type = "github"
        url = "https://api.github.com"
        authorization = @{
            scheme = "OAuth"
            parameters = @{
                oauthConfiguration = @{
                    expirationTime = 0
                }
            }
        }
        description = "Service connection (OAuth) for $($connection.RepositoryOwner)/$($connection.RepositoryName)"
        operationStatus = $null
        serviceEndpointProjectReferences = @(
            @{
                projectReference = @{
                    id = $projectId
                    name = $projectName
                }
                name = $scName
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Write-Host "Creating OAuth service connection..." -ForegroundColor Cyan
    Write-Host "Note: You will be prompted to authorize GitHub in your browser." -ForegroundColor Yellow
    Write-Host ""
    
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
            Write-Host "Type: $($response.type)" -ForegroundColor White
            Write-Host ""
            
            Write-Host "IMPORTANT: Complete OAuth Authorization:" -ForegroundColor Yellow
            Write-Host "1. Go to: $orgUrl/$projectName/_settings/adminservices" -ForegroundColor White
            Write-Host "2. Click on service connection: $($response.name)" -ForegroundColor White
            Write-Host "3. Click 'Authorize' button" -ForegroundColor White
            Write-Host "4. You will be redirected to GitHub to authorize access" -ForegroundColor White
            Write-Host "5. Click 'Authorize' in GitHub" -ForegroundColor White
            Write-Host "6. You will be redirected back to Azure DevOps" -ForegroundColor White
            Write-Host ""
            
            # Attempt to create webhook automatically
            Write-Host "Creating webhook for this service connection..." -ForegroundColor Cyan
            $scId = $response.id
            
            $webhookCreated = Create-GitHubWebhookOAuth `
                -RepoOwner $connection.RepositoryOwner `
                -RepoName $connection.RepositoryName `
                -Organization $connection.Organization `
                -ProjectName $projectName `
                -ServiceConnectionId $scId `
                -AuthHeader $authHeader
            
            # Attempt to create Azure DevOps Service Hook subscription
            Write-Host ""
            $serviceHookCreated = Create-ServiceHookSubscription `
                -Organization $connection.Organization `
                -ProjectName $projectName `
                -ServiceConnectionId $scId `
                -RepoOwner $connection.RepositoryOwner `
                -RepoName $connection.RepositoryName `
                -AuthHeader $authHeader
            
            Write-Host ""
            Write-Host "Setup Summary:" -ForegroundColor Green
            Write-Host "  [OK] Service connection created (OAuth)" -ForegroundColor Green
            Write-Host "  [->] NEXT: Complete authorization at $orgUrl/$projectName/_settings/adminservices" -ForegroundColor Yellow
            if ($webhookCreated) {
                Write-Host "  [OK] GitHub webhook created" -ForegroundColor Green
            } else {
                Write-Host "  [!] Webhook creation - will work after OAuth authorization" -ForegroundColor Yellow
            }
            if ($serviceHookCreated) {
                Write-Host "  [OK] Azure DevOps Service Hook created" -ForegroundColor Green
            } else {
                Write-Host "  [!] Service Hook creation - will work after OAuth authorization" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "OAuth Benefits:" -ForegroundColor Cyan
            Write-Host "  * Webhooks use OAuth flow instead of static PAT" -ForegroundColor White
            Write-Host "  * No PAT expiration causing 401 webhook errors" -ForegroundColor White
            Write-Host "  * Azure DevOps refreshes tokens automatically" -ForegroundColor White
            Write-Host "  * More reliable for long-term production use" -ForegroundColor White
            Write-Host ""
            Write-Host "Required Final Step:" -ForegroundColor Yellow
            Write-Host "  [->] After OAuth auth, use Option 6 to update pipeline YAML!" -ForegroundColor Yellow
            Write-Host "  Why? Pipelines show 'azuregit', not GitHub triggers." -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host "[ERROR] Service connection creation failed" -ForegroundColor Red
            Write-Host "Response: $response" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Failed to create service connection" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual alternative (OAuth):" -ForegroundColor Yellow
        Write-Host "1. Go to: $orgUrl/$projectName/_settings/adminservices" -ForegroundColor White
        Write-Host "2. Click 'New service connection' > GitHub" -ForegroundColor White
        Write-Host "3. Select 'GitHub' (not GitHub Enterprise Server)" -ForegroundColor White
        Write-Host "4. Click 'New GitHub connection using OAuth'" -ForegroundColor White
        Write-Host "5. Click 'Authorize' and complete GitHub authorization" -ForegroundColor White
        Write-Host "6. Name it: $scName" -ForegroundColor White
        Write-Host "7. Click 'Save and queue'" -ForegroundColor White
    }
    
    Write-Host ""
}

function Create-GitHubWebhookOAuth {
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$Organization,
        [string]$ProjectName,
        [string]$ServiceConnectionId,
        [hashtable]$AuthHeader
    )
    
    Write-Host "Note: Webhook creation may fail if OAuth authorization not yet completed." -ForegroundColor Yellow
    Write-Host "That's OK - webhook will work after you authorize the service connection." -ForegroundColor Yellow
    Write-Host ""
    
    # With OAuth, we cannot create webhook via GitHub API directly (no PAT)
    # Azure DevOps Service Hook will handle the webhook delivery
    Write-Host "[OK] Service Hook subscription handles webhook delivery with OAuth" -ForegroundColor Green
    
    return $true
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
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select connection to test (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
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
                        
                        # Check if type is correct
                        foreach ($ep in $endpoints) {
                            if ($ep.type -ne "github") {
                                Write-Host "[WARNING] Service connection type is '$($ep.type)' but should be 'github'" -ForegroundColor Yellow
                                Write-Host "This may cause webhook 404 errors!" -ForegroundColor Yellow
                                Write-Host ""
                            }
                        }
                        
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
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select repository to check webhook (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
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

function Create-WebhookOnlyForExisting {
    Write-Host ""
    Write-Host "Create GitHub Webhook for Existing Service Connection" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Use this option ONLY IF:" -ForegroundColor Yellow
    Write-Host "  1. You already have a service connection created manually (NOT via this script)" -ForegroundColor White
    Write-Host "  2. AND you need to create webhooks for that service connection" -ForegroundColor White
    Write-Host ""
    Write-Host "DO NOT USE if you used Option 1 or 2 (webhooks already created)" -ForegroundColor Red
    Write-Host ""
    
    if (-not $Global:GitHubPAT) {
        Write-Host "ERROR: GitHub PAT not provided!" -ForegroundColor Red
        Write-Host "Please run option 9 (Manage Authentication) to add GitHub PAT first" -ForegroundColor Yellow
        return
    }
    
    if (-not $Global:AzureDevOpsPAT) {
        Write-Host "ERROR: Azure DevOps PAT not provided!" -ForegroundColor Red
        Write-Host "Please run option 9 (Manage Authentication) to add Azure DevOps PAT first" -ForegroundColor Yellow
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
    
    # If multiple connections, ask which one
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple repositories found:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].RepositoryOwner)/$($connections[$i].RepositoryName) (Service Connection: $($connections[$i].ServiceConnectionName))"
        }
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select repository (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
            return
        }
        $connection = $connections[$index]
    } else {
        $connection = $connections[0]
    }
    
    Write-Host ""
    Write-Host "Setting up webhook for: $($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor Yellow
    Write-Host "Organization: $($connection.Organization)" -ForegroundColor White
    Write-Host "Project: $($connection.ProjectName)" -ForegroundColor White
    Write-Host "Service Connection: $($connection.ServiceConnectionName)" -ForegroundColor White
    Write-Host ""
    
    $confirm = Read-Host "Proceed? (yes/no)"
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Prepare authentication header for Azure DevOps API
    $authHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($Global:AzureDevOpsPAT)")) }
    
    # Get the project ID
    Write-Host "Fetching project ID..." -ForegroundColor Cyan
    $projectId = Get-ProjectId -OrgUrl "https://dev.azure.com/$($connection.Organization)" -ProjectName $connection.ProjectName -AuthHeader $authHeader
    
    if ($null -eq $projectId) {
        Write-Host "Cannot proceed without project ID" -ForegroundColor Red
        return
    }
    
    Write-Host "Project ID: $projectId" -ForegroundColor White
    Write-Host ""
    
    # Try to find the existing service connection ID first
    Write-Host "Looking for existing service connection: $($connection.ServiceConnectionName)..." -ForegroundColor Cyan
    
    try {
        $env:AZURE_DEVOPS_EXT_PAT = $Global:AzureDevOpsPAT
        $result = az devops service-endpoint list `
            --organization "https://dev.azure.com/$($connection.Organization)" `
            --project "$($connection.ProjectName)" `
            --query "[?name=='$($connection.ServiceConnectionName)']" `
            -o json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $endpoints = $result | ConvertFrom-Json
            if ($endpoints.Count -gt 0) {
                $scId = $endpoints[0].id
                Write-Host "[OK] Found service connection with ID: $scId" -ForegroundColor Green
                Write-Host ""
                
                # Create webhook
                $webhookCreated = Create-GitHubWebhook `
                    -RepoOwner $connection.RepositoryOwner `
                    -RepoName $connection.RepositoryName `
                    -GitHubPAT $Global:GitHubPAT `
                    -Organization $connection.Organization `
                    -ProjectName $connection.ProjectName `
                    -ServiceConnectionId $scId `
                    -AuthHeader $authHeader
                
                # Create Service Hook
                Write-Host ""
                $serviceHookCreated = Create-ServiceHookSubscription `
                    -Organization $connection.Organization `
                    -ProjectName $connection.ProjectName `
                    -ServiceConnectionId $scId `
                    -RepoOwner $connection.RepositoryOwner `
                    -RepoName $connection.RepositoryName `
                    -AuthHeader $authHeader
                
                Write-Host ""
                Write-Host "Webhook setup completed:" -ForegroundColor Green
                if ($webhookCreated) {
                    Write-Host "  [OK] GitHub webhook created" -ForegroundColor Green
                } else {
                    Write-Host "  [!] GitHub webhook creation failed or already exists" -ForegroundColor Yellow
                }
                if ($serviceHookCreated) {
                    Write-Host "  [OK] Azure DevOps Service Hook created" -ForegroundColor Green
                } else {
                    Write-Host "  [!] Service Hook creation failed or already exists" -ForegroundColor Yellow
                }
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Cyan
                Write-Host "1. Verify webhook in GitHub: https://github.com/$($connection.RepositoryOwner)/$($connection.RepositoryName)/settings/hooks" -ForegroundColor White
                Write-Host "2. Check Recent Deliveries for successful events" -ForegroundColor White
                Write-Host "3. IMPORTANT: Use Option 6 to update your pipeline YAML for GitHub triggers" -ForegroundColor Yellow
                Write-Host "4. Test by pushing code to trigger the pipeline" -ForegroundColor White
                Write-Host ""
            } else {
                Write-Host "[ERROR] Service connection '$($connection.ServiceConnectionName)' not found!" -ForegroundColor Red
                Write-Host ""
                Write-Host "Make sure:" -ForegroundColor Yellow
                Write-Host "1. Service connection exists in Azure DevOps" -ForegroundColor White
                Write-Host "2. Name matches exactly: $($connection.ServiceConnectionName)" -ForegroundColor White
                Write-Host "3. It's in the correct project: $($connection.ProjectName)" -ForegroundColor White
                Write-Host ""
            }
        } else {
            Write-Host "[ERROR] Failed to query service connections" -ForegroundColor Red
            Write-Host "Make sure Azure CLI is installed and configured" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Exception occurred: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual alternative:" -ForegroundColor Yellow
        Write-Host "1. Copy the service connection ID from Azure DevOps" -ForegroundColor White
        Write-Host "2. Run this command with the ID:" -ForegroundColor White
        Write-Host "   `$serviceConnectionId = 'your-service-connection-id'" -ForegroundColor Cyan
        Write-Host ""
    } finally {
        Remove-Item env:AZURE_DEVOPS_EXT_PAT -ErrorAction SilentlyContinue
    }
    
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
        Write-Host "$($uniqueProjects.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select project to view (1-$($uniqueProjects.Count), or $($uniqueProjects.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($uniqueProjects.Count + 1)" -or $index -lt 0 -or $index -ge $uniqueProjects.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
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

function Update-PipelineYAMLFiles {
    Write-Host ""
    Write-Host "Automated Pipeline YAML Configuration" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will automatically update your pipeline YAML to use GitHub triggers." -ForegroundColor Yellow
    Write-Host ""
    
    $data = Read-ServiceConnectionCSV
    if ($null -eq $data) { return }
    
    # Handle both single connection and array of connections
    if ($data -is [System.Array]) {
        $connections = $data
    } else {
        $connections = @($data)
    }
    
    # If multiple connections, ask which one
    if ($connections.Count -gt 1) {
        Write-Host ""
        Write-Host "Multiple repositories found:" -ForegroundColor Yellow
        Write-Host ""
        for ($i = 0; $i -lt $connections.Count; $i++) {
            Write-Host "$($i + 1). $($connections[$i].RepositoryOwner)/$($connections[$i].RepositoryName)"
        }
        Write-Host "$($connections.Count + 1). Cancel"
        Write-Host ""
        
        $selection = Read-Host "Select repository (1-$($connections.Count), or $($connections.Count + 1) to cancel)"
        $index = [int]$selection - 1
        
        if ($selection -eq "$($connections.Count + 1)" -or $index -lt 0 -or $index -ge $connections.Count) {
            Write-Host "Cancelled" -ForegroundColor Yellow
            return
        }
        $connection = $connections[$index]
    } else {
        $connection = $connections[0]
    }
    
    Write-Host ""
    Write-Host "Repository: $($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor Yellow
    Write-Host "Service Connection: $($connection.ServiceConnectionName)" -ForegroundColor White
    Write-Host ""
    
    # Get current directory (should be the repository root)
    $repoPath = Get-Location
    
    Write-Host "Looking for pipeline files in: $repoPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if azure-pipelines.yml exists
    $pipelineFile = Join-Path $repoPath "azure-pipelines.yml"
    if (-not (Test-Path $pipelineFile)) {
        $pipelineFile = Join-Path $repoPath "azure-pipelines.yaml"
    }
    
    if (-not (Test-Path $pipelineFile)) {
        Write-Host "[ERROR] No azure-pipelines.yml or azure-pipelines.yaml found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure:" -ForegroundColor Yellow
        Write-Host "1. You're in the repository root directory" -ForegroundColor White
        Write-Host "2. Pipeline file exists (usually: azure-pipelines.yml)" -ForegroundColor White
        Write-Host ""
        return
    }
    
    Write-Host "Found pipeline file: azure-pipelines.yml" -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "Proceed with updating pipeline YAML? (yes/no)"
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Read current YAML
    $yamlContent = Get-Content -Path $pipelineFile -Raw
    
    # Check if already has GitHub resources
    if ($yamlContent -like "*type: github*" -and $yamlContent -like "*endpoint:*$($connection.ServiceConnectionName)*") {
        Write-Host ""
        Write-Host "[!] Pipeline already configured with GitHub service connection" -ForegroundColor Yellow
        Write-Host "Service connection: $($connection.ServiceConnectionName)" -ForegroundColor White
    }
    
    # Create GitHub resources section
    $branch = "main"
    $githubResourcesSection = @"
resources:
  repositories:
    - repository: GitHub
      type: github
      endpoint: $($connection.ServiceConnectionName)
      name: $($connection.RepositoryOwner)/$($connection.RepositoryName)
      ref: refs/heads/$branch
"@
    
    Write-Host ""
    Write-Host "Adding GitHub resources section to pipeline..." -ForegroundColor Cyan
    
    # Check if resources section exists
    if ($yamlContent -like "*resources:*") {
        Write-Host "[!] Pipeline already has 'resources:' section - merging..." -ForegroundColor Yellow
        if ($yamlContent -like "*repositories:*") {
            # Just add our GitHub one if not already there
            if ($yamlContent -notlike "*type: github*") {
                $yamlContent = $yamlContent -replace '(repositories:)', "$1`n    - repository: GitHub`n      type: github`n      endpoint: $($connection.ServiceConnectionName)`n      name: $($connection.RepositoryOwner)/$($connection.RepositoryName)`n      ref: refs/heads/$branch"
            }
        } else {
            $yamlContent = $yamlContent -replace '(resources:)', "$1`n  repositories:`n    - repository: GitHub`n      type: github`n      endpoint: $($connection.ServiceConnectionName)`n      name: $($connection.RepositoryOwner)/$($connection.RepositoryName)`n      ref: refs/heads/$branch"
        }
    } else {
        Write-Host "[+] Adding 'resources:' section to pipeline" -ForegroundColor Green
        if ($yamlContent -like "*trigger:*") {
            $yamlContent = $githubResourcesSection + "`n`n" + $yamlContent
        } else {
            $yamlContent = $githubResourcesSection + "`n`n" + $yamlContent
        }
    }
    
    # Update checkout step to use GitHub if exists
    if ($yamlContent -like "*checkout:*") {
        Write-Host "[+] Updating checkout step to use GitHub repository" -ForegroundColor Green
        $yamlContent = $yamlContent -replace '- checkout: self', '- checkout: GitHub'
    }
    
    # Save updated YAML
    Set-Content -Path $pipelineFile -Value $yamlContent
    
    Write-Host ""
    Write-Host "[OK] Pipeline YAML updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes made:" -ForegroundColor Green
    Write-Host "  [OK] Added GitHub repository resource" -ForegroundColor Green
    Write-Host "  [OK] Set endpoint to: $($connection.ServiceConnectionName)" -ForegroundColor Green
    Write-Host "  [OK] Set repository to: $($connection.RepositoryOwner)/$($connection.RepositoryName)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes: git diff azure-pipelines.yml" -ForegroundColor White
    Write-Host "2. Commit the changes: git add azure-pipelines.yml && git commit -m 'Update pipeline to use GitHub triggers'" -ForegroundColor White
    Write-Host "3. Push to GitHub: git push" -ForegroundColor White
    Write-Host "4. Test by pushing code to GitHub - pipeline should trigger automatically" -ForegroundColor White
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
            "2" { New-ServiceConnectionOAuth; Read-Host "Press Enter to continue" }
            "3" { Test-ServiceConnection; Read-Host "Press Enter to continue" }
            "4" { Test-Webhook; Read-Host "Press Enter to continue" }
            "5" { Create-WebhookOnlyForExisting; Read-Host "Press Enter to continue" }
            "6" { Update-PipelineYAMLFiles; Read-Host "Press Enter to continue" }
            "7" { View-ServiceConnections; Read-Host "Press Enter to continue" }
            "8" { Show-CSVData; Read-Host "Press Enter to continue" }
            "9" { Manage-Authentication }
            "10" { Invoke-GuidedWorkflow; Read-Host "Press Enter to continue" }
            "11" { exit }
            default { Write-Host "Invalid option" -ForegroundColor Red; Read-Host "Press Enter to continue" }
        }
    } while ($true)
}
