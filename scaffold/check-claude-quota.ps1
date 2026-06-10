#requires -Version 7.0
<#
.SYNOPSIS
    Check Anthropic/Claude quota for your subscription across one or more regions.

.DESCRIPTION
    A quota LIMIT of 0 is why deployments fail with InsufficientQuota. This script
    highlights any region that already has capacity. No secrets stored here.

.EXAMPLE
    ./check-claude-quota.ps1
    ./check-claude-quota.ps1 -Regions eastus2,westus3 -Filter claude
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env'),
    [string[]]$Regions = @('eastus2', 'eastus', 'westus', 'westus2', 'westus3', 'swedencentral', 'westeurope'),
    [string]$Filter = 'claude',
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $k, $v = $line.Split('=', 2)
            [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim())
        }
    }
}

if (-not $SubscriptionId) { $SubscriptionId = [Environment]::GetEnvironmentVariable('AZURE_SUBSCRIPTION_ID') }
if ($SubscriptionId -and $SubscriptionId -notlike '<*>') {
    az account set --subscription $SubscriptionId | Out-Null
}

$anyCapacity = $false
foreach ($r in $Regions) {
    $json = az cognitiveservices usage list --location $r -o json 2>$null
    if (-not $json) { Write-Host "[$r] no usage data"; continue }

    $rows = ($json | ConvertFrom-Json) | Where-Object { $_.name.value -match $Filter }
    if (-not $rows) { Write-Host "[$r] no '$Filter' quotas found"; continue }

    $available = $rows | Where-Object { $_.limit -gt 0 }
    if ($available) {
        $anyCapacity = $true
        Write-Host "[$r] AVAILABLE:" -ForegroundColor Green
        $available | ForEach-Object {
            Write-Host ("    {0} = {1} (used {2})" -f $_.name.value, $_.limit, $_.currentValue)
        }
    }
    else {
        Write-Host "[$r] all '$Filter' quotas are 0" -ForegroundColor Yellow
    }
}

if (-not $anyCapacity) {
    Write-Host "`nNo region has '$Filter' capacity. Request a quota increase (see request-quota.ps1 or the portal)." -ForegroundColor Yellow
}
