# Contributing

Thanks for helping improve this guide!

## Ground rules

- **Never commit secrets.** Use placeholders like `<SUBSCRIPTION_ID>`. Real values go
  in `scaffold/.env` (git-ignored).
- Keep scripts cross-platform PowerShell 7+ and idempotent where possible.

## Run the checks locally

Mirror what CI runs:

```powershell
# 1) Secret / PII scan
pwsh ./tools/scan-secrets.ps1

# 2) Lint
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1

# 3) Bicep build
az bicep build --file ./scaffold/main.bicep
```

All three must pass before a PR is merged.

## Conventions

- Shared helpers live in [`scaffold/_common.ps1`](scaffold/_common.ps1)
  (`Import-DotEnv`, `Resolve-Value`, `Test-Placeholder`).
- Prefer adding a small, focused script over expanding an existing one.
- Update [`README.md`](README.md) and [`scaffold/README.md`](scaffold/README.md) when
  you add or rename a script.
