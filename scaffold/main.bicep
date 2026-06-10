// main.bicep — Deploy an Anthropic Claude model into an EXISTING Microsoft Foundry
// (Azure AI Services) account.
//
// No secrets are stored here. Pass values via parameters or a .bicepparam file.
//
// Deploy:
//   az deployment group create \
//     --resource-group <RESOURCE_GROUP> \
//     --template-file main.bicep \
//     --parameters accountName=<FOUNDRY_ACCOUNT_NAME> organizationName=<YOUR_ORG>
//
// NOTE: Anthropic deployments require provider-compliance data (modelProviderData).
// Bicep tooling may emit a BCP037 warning for that property; the deployment still
// succeeds because ARM accepts it. The PowerShell script (deploy-claude.ps1) is the
// fully verified path if you prefer.

@description('Name of the EXISTING Microsoft Foundry (Azure AI Services) account.')
param accountName string

@description('Claude model id from the catalog, e.g. claude-sonnet-4-5. Use list-claude-models.ps1 to discover.')
param modelName string = 'claude-sonnet-4-5'

@description('Model version, e.g. 20250929.')
param modelVersion string = '20250929'

@description('Deployment name exposed to clients.')
param deploymentName string = modelName

@description('GlobalStandard capacity in TPM (thousands). Requires quota > 0.')
param capacity int = 1

@description('Anthropic provider compliance: industry.')
param industry string = 'Technology'

@description('Anthropic provider compliance: your organization name.')
param organizationName string

@description('Anthropic provider compliance: ISO 3166-1 alpha-2 country code, e.g. AU.')
param countryCode string = 'AU'

resource account 'Microsoft.CognitiveServices/accounts@2026-05-01' existing = {
  name: accountName
}

resource claude 'Microsoft.CognitiveServices/accounts/deployments@2026-05-01' = {
  parent: account
  name: deploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: capacity
  }
  properties: {
    model: {
      format: 'Anthropic'
      name: modelName
      version: modelVersion
    }
    // Required for Anthropic models (see note above).
    modelProviderData: {
      industry: industry
      organizationName: organizationName
      countryCode: countryCode
    }
  }
}

output deployment string = claude.name
output endpoint string = account.properties.endpoint
