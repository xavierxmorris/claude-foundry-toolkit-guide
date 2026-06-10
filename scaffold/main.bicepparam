// main.bicepparam — parameters for main.bicep.
// Copy your values in here OR keep this as a placeholder reference.
// These are PLACEHOLDERS — replace every <...> with your own values.
//
// Deploy:
//   az deployment group create \
//     --resource-group <RESOURCE_GROUP> \
//     --parameters main.bicepparam

using './main.bicep'

param accountName = '<FOUNDRY_ACCOUNT_NAME>'
param modelName = 'claude-sonnet-4-5'
param modelVersion = '20250929'
param deploymentName = 'claude-sonnet-4-5'
param capacity = 1
param industry = 'Technology'
param organizationName = '<YOUR_ORGANIZATION_NAME>'
param countryCode = 'AU'
