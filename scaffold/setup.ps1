#requires -Version 7.0
<#
.SYNOPSIS
    One-command setup: prerequisites -> model list -> quota gate -> deploy -> verify.

.DESCRIPTION
    Orchestrates the other scaffold scripts using values from .env.
    NEVER stores secrets. Use -AutoApprove for an unattended ("YOLO") run.

.EXAMPLE
    Copy-Item .env.example .env   # then edit .env
    ./setup.ps1

.EXAMPLE
    ./setup.ps1 -AutoApprove      # no prompts
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),
    [switch]$AutoApprove,
    [switch]$SkipModelList,
    [switch]$SkipQuotaCheck,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Host "No .env found. Copy .env.example to .env and fill in your values:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .env.example .env" -ForegroundColor Yellow
    exit 1
}
Import-DotEnv $EnvFile

$sub    = Resolve-Value $null 'AZURE_SUBSCRIPTION_ID'
$acct   = Resolve-Value $null 'FOUNDRY_ACCOUNT_NAME'
$model  = Resolve-Value $null 'CLAUDE_MODEL_NAME'
$region = Resolve-Value $null 'FOUNDRY_REGION'

# 1) Prerequisites
Write-Host "`n[1/5] Checking prerequisites..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'check-prereqs.ps1')
if ($LASTEXITCODE -ne 0) { exit 1 }

if (-not (Test-Placeholder $sub)) { az account set --subscription $sub | Out-Null }

# 2) Available models (informational)
if (-not $SkipModelList) {
    Write-Host "`n[2/5] Listing available Claude models..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'list-claude-models.ps1')
}
else {
    Write-Host "`n[2/5] Model list skipped." -ForegroundColor DarkGray
}

# 3) Quota gate
if (-not $SkipQuotaCheck -and -not (Test-Placeholder $region) -and -not (Test-Placeholder $model)) {
    Write-Host "`n[3/5] Checking quota for '$model' in '$region'..." -ForegroundColor Cyan
    $json = az cognitiveservices usage list --location $region -o json 2>$null
    $limit = $null
    if ($json) {
        $rows = ($json | ConvertFrom-Json) | Where-Object { $_.name.value -match [regex]::Escape($model) }
        if ($rows) { $limit = ($rows | Measure-Object -Property limit -Maximum).Maximum }
    }
    if ($null -ne $limit -and $limit -le 0 -and -not $Force) {
        Write-Host "[!] Quota for '$model' in '$region' is 0 — deployment would fail with InsufficientQuota." -ForegroundColor Yellow
        Write-Host "    Request an increase, then re-run setup.ps1:" -ForegroundColor Yellow
        Write-Host "      ./request-quota.ps1 -ContactFirstName <First> -ContactLastName <Last> -ContactEmail <you@example.com> -ContactCountry <AUS>" -ForegroundColor Yellow
        Write-Host "    Or override with -Force to attempt anyway." -ForegroundColor Yellow
        exit 2
    }
    if ($null -eq $limit) {
        Write-Host "[ok] No quota record found for '$model' in '$region'; the deploy step will validate." -ForegroundColor Green
    }
    else {
        Write-Host "[ok] Quota looks available (limit = $limit)." -ForegroundColor Green
    }
}
else {
    Write-Host "`n[3/5] Quota check skipped." -ForegroundColor DarkGray
}

# 4) Confirm + deploy
if (-not $AutoApprove) {
    $answer = Read-Host "`nDeploy '$model' to '$acct'? This may incur cost. [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "Aborted (no changes made)." -ForegroundColor Yellow
        exit 0
    }
}
Write-Host "`n[4/5] Deploying '$model'..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'deploy-claude.ps1') -EnvFile $EnvFile
if ($LASTEXITCODE -ne 0) { exit 1 }

# 5) Verify
Write-Host "`n[5/5] Verifying deployment..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'verify-deployment.ps1') -EnvFile $EnvFile

Write-Host "`nAll done. Open the Foundry Toolkit, reload models, and select '$model'." -ForegroundColor Green
