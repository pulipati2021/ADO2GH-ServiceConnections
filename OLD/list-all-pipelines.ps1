param(
    [string]$Organization = "git-AzDo",
    [string]$ProjectName = "DotNet-GHAS"
)

# Get Azure DevOps PAT from environment or prompt
$token = $env:AZURE_DEVOPS_EXT_PAT
if (-not $token) {
    Write-Host "Azure DevOps PAT needed. Paste your token:" -ForegroundColor Yellow
    $token = Read-Host "PAT (will be hidden)" -AsSecureString
    $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($token))
}

if (-not $token) {
    Write-Host "Error: No PAT provided" -ForegroundColor Red
    exit 1
}

$orgUrl = "https://dev.azure.com/$Organization"
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$token"))

try {
    $url = "$orgUrl/$ProjectName/_apis/pipelines?api-version=7.1-preview.1"
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "QUERYING PIPELINES" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Organization: $Organization" -ForegroundColor Gray
    Write-Host "Project: $ProjectName" -ForegroundColor Gray
    Write-Host ""
    
    $response = Invoke-WebRequest -Uri $url -Headers @{Authorization = "Basic $auth"} -UseBasicParsing -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    
    if ($data.value.Count -eq 0) {
        Write-Host "No pipelines found in project" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "RESULT: Found $($data.value.Count) Pipeline(s)" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $data.value | ForEach-Object {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "Pipeline ID:   $($_.id)" -ForegroundColor Yellow
        Write-Host "Pipeline Name: $($_.name)" -ForegroundColor White
        Write-Host "Folder:        $($_.folder)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Next Step: Run setup-github-service-connection.ps1" -ForegroundColor Cyan
    Write-Host "This will show which pipelines are GitHub-triggered" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
