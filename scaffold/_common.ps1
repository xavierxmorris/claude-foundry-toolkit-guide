#requires -Version 7.0
# Shared helpers for the scaffold scripts.
# Dot-source it:  . (Join-Path $PSScriptRoot '_common.ps1')
# No secrets are stored here.

function Import-DotEnv {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    foreach ($raw in Get-Content -LiteralPath $Path) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith('#') -or -not $line.Contains('=')) { continue }
        $parts = $line.Split('=', 2)
        [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}

function Resolve-Value {
    [CmdletBinding()]
    param(
        [string]$ParamValue,
        [Parameter(Mandatory)][string]$EnvName
    )

    if (-not [string]::IsNullOrWhiteSpace($ParamValue)) { return $ParamValue }
    return [Environment]::GetEnvironmentVariable($EnvName)
}

function Test-Placeholder {
    [CmdletBinding()]
    param([string]$Value)

    return [string]::IsNullOrWhiteSpace($Value) -or $Value -like '<*>'
}
