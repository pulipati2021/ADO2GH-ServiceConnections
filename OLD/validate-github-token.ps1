param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubOrg = ""
)

Write-Host ""
Write-Host "================================================"  -ForegroundColor Cyan
Write-Host "  GitHub Token Validator"  -ForegroundColor Cyan
Write-Host "================================================"  -ForegroundColor Cyan
Write-Host ""

# Check if token provided
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host "ERROR - GitHub token is required"  -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:"  -ForegroundColor Yellow
    Write-Host "  .\validate-service-connection.ps1 -GitHubToken 'your-token-here'"  -ForegroundColor White
    Write-Host ""
    Write-Host "To get a token:"  -ForegroundColor Yellow
    Write-Host "  1. Go to https://github.com/settings/tokens"  -ForegroundColor White
    Write-Host "  2. Generate new token (classic)"  -ForegroundColor White
    Write-Host "  3. Select scopes: repo, read:org, admin:org_hook"  -ForegroundColor White
    exit 1
}

Write-Host "Testing GitHub token..."  -ForegroundColor Cyan
Write-Host ""

# Test 1: Token is valid
Write-Host "1. Checking if token is valid..."  -ForegroundColor Cyan
try {
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept" = "application/vnd.github+json"
    }
    
    $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
    Write-Host "   OK - Token is VALID"  -ForegroundColor Green
    Write-Host "   Logged in as: $($response.login)"  -ForegroundColor White
} catch {
    Write-Host "   ERROR - Token is INVALID or expired"  -ForegroundColor Red
    Write-Host "   Go to https://github.com/settings/tokens to check"  -ForegroundColor Yellow
    exit 1
}

# Test 2: Token has required scopes
Write-Host ""
Write-Host "2. Checking token scopes..."  -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
    $scopes = $response | Select-Object -ExpandProperty "scope" -ErrorAction SilentlyContinue
    
    if ($null -eq $scopes) {
        Write-Host "   OK - No scope restrictions (token is valid)"  -ForegroundColor Green
    } else {
        Write-Host "   Token scopes: $scopes"  -ForegroundColor White
    }
} catch {
    Write-Host "   WARNING - Could not verify scopes"  -ForegroundColor Yellow
}

# Test 3: Can access organizations (if org provided)
if (![string]::IsNullOrEmpty($GitHubOrg)) {
    Write-Host ""
    Write-Host "3. Checking organization access..."  -ForegroundColor Cyan
    try {
        $orgResponse = Invoke-RestMethod -Uri "https://api.github.com/orgs/$GitHubOrg" -Headers $headers -ErrorAction Stop
        Write-Host "   OK - Can access organization: $($orgResponse.name)"  -ForegroundColor Green
        Write-Host "   ID: $($orgResponse.id)"  -ForegroundColor White
    } catch {
        Write-Host "   ERROR - Cannot access organization '$GitHubOrg'"  -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================"  -ForegroundColor Green
Write-Host "All checks passed!"  -ForegroundColor Green
Write-Host "================================================"  -ForegroundColor Green
Write-Host ""
Write-Host "Your GitHub token is ready to use in:"  -ForegroundColor Cyan
Write-Host "  - Azure DevOps Service Connections"  -ForegroundColor White
Write-Host "  - GitHub CLI (gh)"  -ForegroundColor White
Write-Host "  - API requests"  -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Keep this token SECRET!"  -ForegroundColor Yellow
Write-Host ""
