# Changelog

All notable changes to this project are documented here.

## [0.2.2] - 2026-06-10

### Fixed
- `check-prereqs.ps1` no longer reports success while leaving a non-zero exit code when
  Azure CLI is installed but not signed in. Sign-in is now a hard prerequisite and the
  script exits 0 explicitly on success (prevents `setup.ps1` from aborting after
  printing "Prerequisites OK").
- `request-quota.ps1` dry-run preview now prints real line breaks instead of a literal
  `\n` sequence.

### Changed
- Scaffold scripts now share `.env` loading and value resolution via `_common.ps1`
  (removed duplicated inline helpers in `deploy-claude.ps1`, `list-claude-models.ps1`,
  `check-claude-quota.ps1`, and `request-quota.ps1`).

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
