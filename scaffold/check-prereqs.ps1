#requires -Version 7.0
<#
.SYNOPSIS
    Check that the tools needed to deploy a Claude model are present.

.DESCRIPTION
    Verifies PowerShell 7+, the Azure CLI, and sign-in status. No secrets are read
    or stored. Exits non-zero if a hard prerequisite is missing.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ok = $true

# PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[x] PowerShell 7+ is required (found $($PSVersionTable.PSVersion))." -ForegroundColor Red
    $ok = $false
}
else {
    Write-Host "[ok] PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green
}

# Azure CLI
$az = Get-Command az -ErrorAction SilentlyContinue
if (-not $az) {
    Write-Host "[x] Azure CLI (az) not found. Install: https://aka.ms/azcli" -ForegroundColor Red
    $ok = $false
}
else {
    Write-Host "[ok] Azure CLI: $($az.Source)" -ForegroundColor Green

    $account = az account show -o json 2>$null
    if (-not $account) {
        Write-Host "[!] Not signed in. Run: az login" -ForegroundColor Yellow
    }
    else {
        $info = $account | ConvertFrom-Json
        Write-Host "[ok] Signed in as subscription: $($info.name)" -ForegroundColor Green
    }
}

if (-not $ok) {
    Write-Host "`nPrerequisite check failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nPrerequisites OK." -ForegroundColor Green
