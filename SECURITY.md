# Security Policy

## This repository contains no secrets

Every subscription ID, tenant ID, resource name, project name, and email in this repo
is a **placeholder** (e.g. `<SUBSCRIPTION_ID>`, `<FOUNDRY_ACCOUNT_NAME>`).

Your real values live only in `scaffold/.env`, which is **git-ignored** and never
committed. See [Where to put your own values](README.md#where-to-put-your-own-values).

## Automated protection

Every push and pull request runs [`tools/scan-secrets.ps1`](tools/scan-secrets.ps1)
in CI. It fails the build if it detects:

- an Azure-style GUID (subscription/tenant ID) that isn't an allow-listed public service ID,
- an API token / key (GitHub, Slack, AWS, OpenAI) or a PEM private key,
- a non-example email address.

Run it yourself any time:

```powershell
pwsh ./tools/scan-secrets.ps1
```

## Good habits

- Prefer `az login` and managed identity over long-lived keys.
- Never paste secrets into issues, PRs, or chat tools.
- Rotate any credential that may have been exposed.

## Reporting a vulnerability

Please open a **private** GitHub Security Advisory on this repository
(*Security → Advisories → Report a vulnerability*) rather than a public issue.
