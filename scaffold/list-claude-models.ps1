#requires -Version 7.0
<#
.SYNOPSIS
    List the REAL Anthropic Claude models deployable to your Foundry account.

.DESCRIPTION
    Prevents the #1 cause of "Model is not connected": guessing a model name.
    Reads values from .env or parameters. No secrets are stored in this file.

.EXAMPLE
    ./list-claude-models.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile        = (Join-Path $PSScriptRoot '.env'),
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$AccountName,
    [string]$Filter = 'Anthropic'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')
Import-DotEnv $EnvFile

$SubscriptionId = Resolve-Value $SubscriptionId 'AZURE_SUBSCRIPTION_ID'
$ResourceGroup  = Resolve-Value $ResourceGroup  'FOUNDRY_RESOURCE_GROUP'
$AccountName    = Resolve-Value $AccountName    'FOUNDRY_ACCOUNT_NAME'

if (($AccountName -like '<*>') -or [string]::IsNullOrWhiteSpace($AccountName)) {
    Write-Error "Set FOUNDRY_ACCOUNT_NAME (and resource group / subscription) in your .env first."
    exit 1
}

if ($SubscriptionId -and $SubscriptionId -notlike '<*>') {
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Deployable '$Filter' models for '$AccountName':" -ForegroundColor Cyan
az cognitiveservices account list-models `
    --name $AccountName `
    --resource-group $ResourceGroup `
    --query "[?format=='$Filter'].{name:name, version:version, sku:skus[0].name}" `
    -o table
