#requires -Version 7.0
<#
.SYNOPSIS
    Verify that a Claude deployment exists and is in the 'Succeeded' state.

.DESCRIPTION
    Reads config from .env (or parameters). No secrets are stored in this file.

.EXAMPLE
    ./verify-deployment.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$AccountName,
    [string]$DeploymentName
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')
Import-DotEnv $EnvFile

$SubscriptionId = Resolve-Value $SubscriptionId 'AZURE_SUBSCRIPTION_ID'
$ResourceGroup  = Resolve-Value $ResourceGroup  'FOUNDRY_RESOURCE_GROUP'
$AccountName    = Resolve-Value $AccountName    'FOUNDRY_ACCOUNT_NAME'
$DeploymentName = Resolve-Value $DeploymentName 'CLAUDE_DEPLOYMENT_NAME'
if (Test-Placeholder $DeploymentName) { $DeploymentName = Resolve-Value $null 'CLAUDE_MODEL_NAME' }

foreach ($pair in @(
    @{ n = 'FOUNDRY_RESOURCE_GROUP'; v = $ResourceGroup },
    @{ n = 'FOUNDRY_ACCOUNT_NAME'; v = $AccountName },
    @{ n = 'CLAUDE_DEPLOYMENT_NAME/CLAUDE_MODEL_NAME'; v = $DeploymentName }
)) {
    if (Test-Placeholder $pair.v) {
        Write-Host "Missing value: $($pair.n). Edit your .env first." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Placeholder $SubscriptionId)) {
    az account set --subscription $SubscriptionId | Out-Null
}

$state = az cognitiveservices account deployment show `
    --name $AccountName `
    --resource-group $ResourceGroup `
    --deployment-name $DeploymentName `
    --query "properties.provisioningState" -o tsv 2>$null

if ($state -eq 'Succeeded') {
    Write-Host "[ok] Deployment '$DeploymentName' is Succeeded. Select it in the Foundry Toolkit." -ForegroundColor Green
}
elseif (-not $state) {
    Write-Host "[x] Deployment '$DeploymentName' not found in '$AccountName'." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "[!] Deployment '$DeploymentName' state: $state" -ForegroundColor Yellow
}
