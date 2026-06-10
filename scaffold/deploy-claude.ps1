#requires -Version 7.0
<#
.SYNOPSIS
    Deploy an Anthropic Claude model into a Microsoft Foundry (Azure AI Services) account.

.DESCRIPTION
    Reads configuration from a .env file (or environment variables / parameters).
    NEVER hardcode subscription IDs, secrets, or emails in this file.

    Verified path: ARM REST PUT with the Anthropic "modelProviderData" form, which is
    required for Claude deployments.

.EXAMPLE
    Copy-Item .env.example .env   # then edit .env
    ./deploy-claude.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile        = (Join-Path $PSScriptRoot '.env'),
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$AccountName,
    [string]$ModelName,
    [string]$ModelVersion,
    [string]$DeploymentName,
    [int]   $Capacity       = 0,
    [string]$Industry,
    [string]$OrgName,
    [string]$CountryCode,
    [string]$ApiVersion     = '2026-05-01'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

# --- Load .env and resolve values: explicit param > env var ---
Import-DotEnv $EnvFile

$SubscriptionId = Resolve-Value $SubscriptionId 'AZURE_SUBSCRIPTION_ID'
$ResourceGroup  = Resolve-Value $ResourceGroup  'FOUNDRY_RESOURCE_GROUP'
$AccountName    = Resolve-Value $AccountName    'FOUNDRY_ACCOUNT_NAME'
$ModelName      = Resolve-Value $ModelName      'CLAUDE_MODEL_NAME'
$ModelVersion   = Resolve-Value $ModelVersion   'CLAUDE_MODEL_VERSION'
$DeploymentName = Resolve-Value $DeploymentName 'CLAUDE_DEPLOYMENT_NAME'
$Industry       = Resolve-Value $Industry       'ANTHROPIC_INDUSTRY'
$OrgName        = Resolve-Value $OrgName        'ANTHROPIC_ORG_NAME'
$CountryCode    = Resolve-Value $CountryCode    'ANTHROPIC_COUNTRY_CODE'
if ($Capacity -le 0) {
    $envCap = [Environment]::GetEnvironmentVariable('CLAUDE_CAPACITY')
    $Capacity = if ($envCap) { [int]$envCap } else { 1 }
}
if ([string]::IsNullOrWhiteSpace($DeploymentName)) { $DeploymentName = $ModelName }

# --- Validate ---
$missing = @()
foreach ($pair in @(
    @{ n = 'AZURE_SUBSCRIPTION_ID'; v = $SubscriptionId },
    @{ n = 'FOUNDRY_RESOURCE_GROUP'; v = $ResourceGroup },
    @{ n = 'FOUNDRY_ACCOUNT_NAME'; v = $AccountName },
    @{ n = 'CLAUDE_MODEL_NAME'; v = $ModelName },
    @{ n = 'CLAUDE_MODEL_VERSION'; v = $ModelVersion },
    @{ n = 'ANTHROPIC_INDUSTRY'; v = $Industry },
    @{ n = 'ANTHROPIC_ORG_NAME'; v = $OrgName },
    @{ n = 'ANTHROPIC_COUNTRY_CODE'; v = $CountryCode }
)) { if ([string]::IsNullOrWhiteSpace($pair.v) -or $pair.v -like '<*>') { $missing += $pair.n } }

if ($missing.Count -gt 0) {
    Write-Error "Missing/placeholder values: $($missing -join ', '). Edit your .env (copy from .env.example)."
    exit 1
}

# --- Build the deployment body ---
$body = @{
    sku        = @{ name = 'GlobalStandard'; capacity = $Capacity }
    properties = @{
        model             = @{ format = 'Anthropic'; name = $ModelName; version = $ModelVersion }
        modelProviderData = @{ industry = $Industry; organizationName = $OrgName; countryCode = $CountryCode }
    }
} | ConvertTo-Json -Depth 6

$bodyFile = New-TemporaryFile
$body | Set-Content -Path $bodyFile -Encoding utf8

$url = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" +
       "/providers/Microsoft.CognitiveServices/accounts/$AccountName/deployments/$DeploymentName" +
       "?api-version=$ApiVersion"

Write-Host "Switching subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId | Out-Null

Write-Host "Deploying '$ModelName' (v$ModelVersion) as '$DeploymentName' to '$AccountName'..." -ForegroundColor Cyan
try {
    az rest --method put --url $url --body "@$bodyFile" --headers "Content-Type=application/json" -o json
    Write-Host "`nDone. Verify with:" -ForegroundColor Green
    Write-Host "  az cognitiveservices account deployment show --name `"$AccountName`" --resource-group `"$ResourceGroup`" --deployment-name `"$DeploymentName`" --query `"properties.provisioningState`" -o tsv"
}
finally {
    Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue
}
