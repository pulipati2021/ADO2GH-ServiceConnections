param(
    [Parameter(Mandatory = $false)]
    [string]$LocalRepoPath = (Get-Location),
    [Parameter(Mandatory = $false)]
    [string]$ServiceConnectionName = "github-service-connection",
    [Parameter(Mandatory = $false)]
    [string]$RepositoryOwner,
    [Parameter(Mandatory = $false)]
    [string]$RepositoryName,
    [Parameter(Mandatory = $false)]
    [string]$Branch = "main"
)

# Colors for output
$Colors = @{
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
}

function Update-PipelineYAML {
    param(
        [string]$LocalRepoPath,
        [string]$ServiceConnectionName,
        [string]$RepositoryOwner,
        [string]$RepositoryName,
        [string]$Branch
    )
    
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "   Pipeline YAML Automation - GitHub Trigger Setup" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Find pipeline YAML files
    $pipelineFiles = @()
    $pipelineFiles += Get-ChildItem -Path $LocalRepoPath -Name "azure-pipelines*.yml" -Recurse -ErrorAction SilentlyContinue
    $pipelineFiles += Get-ChildItem -Path $LocalRepoPath -Name "azure-pipelines*.yaml" -Recurse -ErrorAction SilentlyContinue
    
    if ($pipelineFiles.Count -eq 0) {
        Write-Host "[ERROR] No azure-pipelines.yml files found in $LocalRepoPath" -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure:" -ForegroundColor Yellow
        Write-Host "1. You're in the repository root directory" -ForegroundColor White
        Write-Host "2. Pipeline YAML file exists (usually: azure-pipelines.yml)" -ForegroundColor White
        Write-Host ""
        return $false
    }
    
    Write-Host "Found $($pipelineFiles.Count) pipeline file(s):" -ForegroundColor Yellow
    for ($i = 0; $i -lt $pipelineFiles.Count; $i++) {
        Write-Host "$($i + 1). $($pipelineFiles[$i])" -ForegroundColor White
    }
    Write-Host ""
    
    # Select file if multiple
    if ($pipelineFiles.Count -gt 1) {
        $selection = Read-Host "Select pipeline file to update (1-$($pipelineFiles.Count))"
        $index = [int]$selection - 1
        if ($index -lt 0 -or $index -ge $pipelineFiles.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return $false
        }
        $pipelineFile = $pipelineFiles[$index]
    } else {
        $pipelineFile = $pipelineFiles[0]
    }
    
    $pipelineFilePath = Join-Path $LocalRepoPath $pipelineFile
    
    Write-Host "Updating: $pipelineFile" -ForegroundColor Cyan
    Write-Host ""
    
    # Read current YAML
    $yamlContent = Get-Content -Path $pipelineFilePath -Raw
    
    # Check if already has GitHub resources
    if ($yamlContent -like "*type: github*" -and $yamlContent -like "*endpoint:*$ServiceConnectionName*") {
        Write-Host "[!] Pipeline already configured with GitHub service connection" -ForegroundColor Yellow
        Write-Host "Service connection: $ServiceConnectionName" -ForegroundColor White
        Write-Host ""
        $confirm = Read-Host "Update anyway? (yes/no)"
        if ($confirm -ne "yes" -and $confirm -ne "y") {
            Write-Host "Skipped" -ForegroundColor Yellow
            return $false
        }
    }
    
    # Create GitHub resources section
    $githubResourcesSection = @"
resources:
  repositories:
    - repository: GitHub
      type: github
      endpoint: $ServiceConnectionName
      name: $RepositoryOwner/$RepositoryName
      ref: refs/heads/$Branch
"@
    
    # Check if resources section exists
    if ($yamlContent -like "*resources:*") {
        Write-Host "[!] Pipeline already has 'resources:' section" -ForegroundColor Yellow
        Write-Host "Merging GitHub repository configuration..." -ForegroundColor Cyan
        
        # Replace or add repositories
        if ($yamlContent -like "*repositories:*") {
            # Already has repositories, just add our GitHub one
            $yamlContent = $yamlContent -replace '(repositories:.*)', "$1`n    - repository: GitHub`n      type: github`n      endpoint: $ServiceConnectionName`n      name: $RepositoryOwner/$RepositoryName`n      ref: refs/heads/$Branch"
        } else {
            # Has resources but no repositories, add it
            $yamlContent = $yamlContent -replace '(resources:)', "$1`n  repositories:`n    - repository: GitHub`n      type: github`n      endpoint: $ServiceConnectionName`n      name: $RepositoryOwner/$RepositoryName`n      ref: refs/heads/$Branch"
        }
    } else {
        Write-Host "[+] Adding 'resources:' section to pipeline" -ForegroundColor Green
        # No resources section, add it after trigger or at beginning
        if ($yamlContent -like "*trigger:*") {
            $yamlContent = $yamlContent -replace '(trigger:.*?)(\n[a-z])', "`$1`n`n$githubResourcesSection`n`$2"
        } else {
            $yamlContent = $githubResourcesSection + "`n`n" + $yamlContent
        }
    }
    
    # Update trigger to include GitHub branch
    if ($yamlContent -like "*trigger:*") {
        Write-Host "[+] Updating trigger configuration" -ForegroundColor Green
        # Ensure trigger has branch filter for our branch
        if ($yamlContent -notlike "*branches:*include:*$Branch*") {
            $yamlContent = $yamlContent -replace '(trigger:.*?)(\n)', '$1`n  branches:`n    include:`n      - $Branch$2'
        }
    }
    
    # Update checkout step to use GitHub
    if ($yamlContent -like "*checkout:*") {
        Write-Host "[+] Updating checkout step to use GitHub repository" -ForegroundColor Green
        $yamlContent = $yamlContent -replace '(steps:.*?)(- checkout:.*?\n)', '$1- checkout: GitHub`n'
    } else {
        Write-Host "[!] No checkout step found - you may need to add it manually" -ForegroundColor Yellow
    }
    
    # Save updated YAML
    Set-Content -Path $pipelineFilePath -Value $yamlContent
    Write-Host "[OK] Pipeline YAML updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes made:" -ForegroundColor Cyan
    Write-Host "  * Added GitHub repository resource" -ForegroundColor White
    Write-Host "  * Set endpoint to: $ServiceConnectionName" -ForegroundColor White
    Write-Host "  * Set repository to: $RepositoryOwner/$RepositoryName" -ForegroundColor White
    Write-Host "  * Set trigger branch to: $Branch" -ForegroundColor White
    Write-Host "  * Updated checkout step to use GitHub" -ForegroundColor White
    Write-Host ""
    
    # Show updated content
    Write-Host "Updated YAML preview:" -ForegroundColor Yellow
    Write-Host "---" -ForegroundColor White
    $yamlContent | Select-Object -First 30 | Write-Host
    Write-Host "---" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes in: $pipelineFile" -ForegroundColor White
    Write-Host "2. Commit the changes: git add $pipelineFile && git commit -m 'Update pipeline to use GitHub triggers'" -ForegroundColor White
    Write-Host "3. Push to GitHub: git push" -ForegroundColor White
    Write-Host "4. Test by pushing code to GitHub - pipeline should trigger automatically" -ForegroundColor White
    Write-Host ""
    
    return $true
}

# Main execution
if ($LocalRepoPath -and $ServiceConnectionName -and $RepositoryOwner -and $RepositoryName) {
    Write-Host "Running in automated mode..." -ForegroundColor Cyan
    Update-PipelineYAML -LocalRepoPath $LocalRepoPath -ServiceConnectionName $ServiceConnectionName -RepositoryOwner $RepositoryOwner -RepositoryName $RepositoryName -Branch $Branch
} else {
    Write-Host ""
    Write-Host "Pipeline YAML Automation Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage (in automated script):" -ForegroundColor Yellow
    Write-Host ".\Update-PipelineYAML.ps1 -LocalRepoPath 'C:\repos\my-repo' -ServiceConnectionName 'github-service-connection' -RepositoryOwner 'my-org' -RepositoryName 'my-repo' -Branch 'main'" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run interactively:" -ForegroundColor Yellow
    Write-Host ".\Update-PipelineYAML.ps1" -ForegroundColor White
    Write-Host ""
}
