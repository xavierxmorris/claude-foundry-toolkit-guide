#requires -Version 7.0
<#
.SYNOPSIS
    Scaffold a quota-increase support ticket for Claude/Cognitive Services.

.DESCRIPTION
    Anthropic model quota typically starts at 0 and must be raised by Microsoft via a
    support ticket (the same thing the portal's "Request quota" button submits).

    This script is OPT-IN: it prints the command by default and only files the ticket
    when you pass -Execute. Fill in YOUR OWN contact details — none are stored here.

    Requires: az extension add --name support

.EXAMPLE
    # Dry run (prints what it would do):
    ./request-quota.ps1 -ContactFirstName Ada -ContactLastName Lovelace `
        -ContactEmail you@example.com -ContactCountry AUS

    # Actually file it:
    ./request-quota.ps1 ... -Execute
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),

    [Parameter(Mandatory)][string]$ContactFirstName,
    [Parameter(Mandatory)][string]$ContactLastName,
    [Parameter(Mandatory)][string]$ContactEmail,
    [Parameter(Mandatory)][string]$ContactCountry,      # ISO 3166-1 alpha-3, e.g. AUS, USA

    [string]$ContactTimezone = 'AUS Eastern Standard Time',
    [string]$ContactLanguage = 'en-us',
    [ValidateSet('minimal', 'moderate', 'critical')][string]$Severity = 'moderate',
    [string]$SubscriptionId,
    [string]$ModelName,
    [string]$Region,
    [int]$RequestedTpmThousands = 50,
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')
Import-DotEnv $EnvFile

$SubscriptionId = Resolve-Value $SubscriptionId 'AZURE_SUBSCRIPTION_ID'
$ModelName      = Resolve-Value $ModelName      'CLAUDE_MODEL_NAME'
$Region         = Resolve-Value $Region         'FOUNDRY_REGION'

# Quota support service + Cognitive Services problem classification (stable GUIDs).
$quotaService          = '06bfd9d3-516b-d5c6-5802-169c800dec89'
$cognitiveProblemClass = '2a0a9b68-0981-14f4-d590-a7eecb8d6bee'
$problemClassification = "/providers/Microsoft.Support/services/$quotaService/problemClassifications/$cognitiveProblemClass"

$ticketName = "claude-quota-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
$title      = "Quota increase: $ModelName ($Region) to $RequestedTpmThousands K TPM"
$description = @"
Please increase GlobalStandard quota for model '$ModelName' in region '$Region'
to $RequestedTpmThousands (Tokens Per Minute, thousands) on subscription $SubscriptionId.
Current limit is 0. Use case: Microsoft Foundry / Foundry Toolkit model deployment.
"@

Write-Host "Ensuring 'support' CLI extension..." -ForegroundColor Cyan
az extension add --name support --only-show-errors 2>$null | Out-Null

$cmd = @(
    'az support in-subscription tickets create',
    "--ticket-name `"$ticketName`"",
    "--title `"$title`"",
    "--description `"$description`"",
    "--severity $Severity",
    "--advanced-diagnostic-consent Yes",
    "--problem-classification `"$problemClassification`"",
    "--contact-first-name `"$ContactFirstName`"",
    "--contact-last-name `"$ContactLastName`"",
    "--contact-email `"$ContactEmail`"",
    "--contact-country `"$ContactCountry`"",
    "--contact-language `"$ContactLanguage`"",
    "--contact-method email",
    "--contact-timezone `"$ContactTimezone`"",
    "--subscription `"$SubscriptionId`""
) -join "`n    "

if (-not $Execute) {
    Write-Host "`n--- DRY RUN (add -Execute to file the ticket) ---`n" -ForegroundColor Yellow
    Write-Host $cmd
    return
}

Write-Host "Filing support ticket '$ticketName'..." -ForegroundColor Cyan
az support in-subscription tickets create `
    --ticket-name $ticketName `
    --title $title `
    --description $description `
    --severity $Severity `
    --advanced-diagnostic-consent Yes `
    --problem-classification $problemClassification `
    --contact-first-name $ContactFirstName `
    --contact-last-name $ContactLastName `
    --contact-email $ContactEmail `
    --contact-country $ContactCountry `
    --contact-language $ContactLanguage `
    --contact-method email `
    --contact-timezone $ContactTimezone `
    --subscription $SubscriptionId `
    -o json
