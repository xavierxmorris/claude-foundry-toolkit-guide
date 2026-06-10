# Scaffold — minimal templates

Copy `.env.example` to `.env`, fill in **your own** values, then run the scripts.
`.env` is git-ignored and never committed.

| File | Purpose |
|------|---------|
| `.env.example` | Template of all values. Copy to `.env` and edit. |
| `list-claude-models.ps1` | Print the **real** deployable Claude model names/versions. |
| `check-claude-quota.ps1` | Check/scan Claude quota across regions (limit 0 = blocked). |
| `request-quota.ps1` | Opt-in support-ticket scaffold to raise quota (dry-run by default). |
| `deploy-claude.ps1` | Deploy a Claude model (verified REST path with provider data). |
| `deployment-body.json` | Raw REST body template if you prefer `az rest` directly. |
| `main.bicep` | Infrastructure-as-Code alternative for the deployment. |

## Quick start (PowerShell 7+)

```powershell
cd scaffold
Copy-Item .env.example .env
# edit .env with your values

./list-claude-models.ps1     # confirm a real model name/version
./check-claude-quota.ps1     # make sure limit > 0
./deploy-claude.ps1          # deploy
```

## Where do my values come from?

- **AZURE_SUBSCRIPTION_ID** — `az account show --query id -o tsv`
- **FOUNDRY_RESOURCE_GROUP / FOUNDRY_ACCOUNT_NAME** — your AI Services resource in the
  Azure portal or `az cognitiveservices account list -o table`
- **CLAUDE_MODEL_NAME / CLAUDE_MODEL_VERSION** — from `list-claude-models.ps1`
- **ANTHROPIC_ORG_NAME / INDUSTRY / COUNTRY_CODE** — your organization details

> 🔐 Never commit `.env`, subscription IDs, tenant IDs, keys, or emails.
