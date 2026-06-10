#requires -Version 7.0
<#
.SYNOPSIS
    Self-contained secret / PII scanner for tracked files. No external dependencies.

.DESCRIPTION
    Fails (exit 1) if a likely credential slips into the repo so it stays safe to keep
    public. Flags:
      - Azure-style GUIDs (subscription/tenant IDs) — except a small allow-list of
        well-known PUBLIC service GUIDs used by the scaffold.
      - API tokens / keys (GitHub, Slack, AWS, OpenAI, PEM private keys).
      - Email addresses, except example/placeholder domains.

    Only scans files tracked by git, and skips itself (it intentionally contains the
    detection patterns).

.EXAMPLE
    pwsh ./tools/scan-secrets.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { Write-Host "Not a git repository." -ForegroundColor Red; exit 1 }
$repoRoot = $repoRoot.Trim()
Push-Location $repoRoot
try {
    $selfRel  = 'tools/scan-secrets.ps1'
    $skipExt  = '\.(png|jpg|jpeg|gif|webp|ico|pdf|zip|gz|tar|exe|dll|woff2?)$'
    $files    = (git ls-files) | Where-Object { $_ -and $_ -ne $selfRel -and $_ -notmatch $skipExt }

    # PUBLIC, non-secret GUIDs the scaffold legitimately references.
    $allowGuids = @(
        '06bfd9d3-516b-d5c6-5802-169c800dec89',  # Support service: quotas
        '2a0a9b68-0981-14f4-d590-a7eecb8d6bee'   # Problem classification: Cognitive Services
    )

    $guidRx     = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    $emailRx    = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    $emailAllow = '(@example\.(com|org|net)|users\.noreply\.github\.com)'
    $tokenRx    = '(gh[oprsu]_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]+|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'

    $findings = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        $lines = Get-Content -LiteralPath $file -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $num  = $i + 1
            foreach ($m in [regex]::Matches($line, $guidRx)) {
                if ($allowGuids -notcontains $m.Value.ToLower()) {
                    $findings.Add("[$file`:$num] GUID: $($m.Value)")
                }
            }
            foreach ($m in [regex]::Matches($line, $emailRx)) {
                if ($m.Value -notmatch $emailAllow) {
                    $findings.Add("[$file`:$num] email: $($m.Value)")
                }
            }
            foreach ($m in [regex]::Matches($line, $tokenRx)) {
                $prefix = $m.Value.Substring(0, [Math]::Min(10, $m.Value.Length))
                $findings.Add("[$file`:$num] token-like: $prefix...")
            }
        }
    }

    if ($findings.Count -gt 0) {
        Write-Host "Potential secrets / PII detected:" -ForegroundColor Red
        $findings | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host "`nIf these are placeholders, update the allow-list in $selfRel." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "No secrets or PII detected in tracked files." -ForegroundColor Green
}
finally {
    Pop-Location
}
