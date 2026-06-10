# Changelog

All notable changes to this project are documented here.

## [0.2.1] - 2026-06-10

### Changed
- CI: pinned `actions/checkout` to v6.0.3 by commit SHA (resolves the Node.js 20
  deprecation warning and hardens the supply chain).
- CI: added `workflow_dispatch` (manual runs) and a `concurrency` group that cancels
  superseded in-progress runs.

## [0.2.0] - 2026-06-10

### Added
- `scaffold/setup.ps1` — one-command orchestrator (prereqs → model list → quota gate →
  deploy → verify) with `-AutoApprove` for unattended runs.
- `scaffold/check-prereqs.ps1` — verifies PowerShell, Azure CLI, and sign-in.
- `scaffold/verify-deployment.ps1` — confirms a deployment reached `Succeeded`.
- `scaffold/_common.ps1` — shared `.env` / value-resolution helpers.
- `scaffold/main.bicepparam` — parameter file for the Bicep template.
- `tools/scan-secrets.ps1` — self-contained secret / PII scanner.
- GitHub Actions CI (`.github/workflows/ci.yml`): secret scan, PSScriptAnalyzer lint,
  and Bicep build.
- `SECURITY.md`, `CONTRIBUTING.md`, `PSScriptAnalyzerSettings.psd1`.

## [0.1.0] - 2026-06-10

### Added
- Initial step-by-step guide and scaffold: `list-claude-models.ps1`,
  `check-claude-quota.ps1`, `request-quota.ps1`, `deploy-claude.ps1`,
  `deployment-body.json`, `main.bicep`, `.env.example`.
