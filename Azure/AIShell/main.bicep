//main.bicep - NOT WORKING
@description('This is the name of your AI Service Account')
param aiserviceaccountname string = 'icewolf-aishell'

@description('Custom domain name for the endpoint')
param customDomainName string = 'icewolf-aishell'

@description('Name of the deployment')
param modeldeploymentname string = 'icewolf-aishell-deployment'

@description('The model being deployed')
param model string = 'o4-mini'

@description('Version of the model being deployed')
param modelversion string = '2025-04-16'

@description('Capacity for specific model used')
param capacity int = 100

@description('Location for all resources.')
@allowed([
  'westus'
  'southcentralus'
  'swedencentral'
  ])
param location string = 'westus'

@allowed([
  'S0'
])
param sku string = 'S0'

resource openAIService 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiserviceaccountname
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: sku
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: customDomainName
  }
}

resource azopenaideployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
    parent: openAIService
    name: modeldeploymentname
    properties: {
        model: {
            format: 'OpenAI'
            name: model
            version: modelversion
        }
    }
    sku: {
      name: sku
      capacity: capacity
    }
}

output openAIServiceEndpoint string = openAIService.properties.endpoint


//
param accounts_icewolf_aishell_01_name string = 'icewolf-aishell-01'

resource accounts_icewolf_aishell_01_name_resource 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accounts_icewolf_aishell_01_name
  location: 'westeurope'
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    apiProperties: {}
    customSubDomainName: accounts_icewolf_aishell_01_name
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    allowProjectManagement: false
    publicNetworkAccess: 'Enabled'
  }
}

resource accounts_icewolf_aishell_01_name_Default 'Microsoft.CognitiveServices/accounts/defenderForAISettings@2025-06-01' = {
  parent: accounts_icewolf_aishell_01_name_resource
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource accounts_icewolf_aishell_01_name_o4_mini 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: accounts_icewolf_aishell_01_name_resource
  name: 'o4-mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'o4-mini'
      version: '2025-04-16'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: 20
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

resource accounts_icewolf_aishell_01_name_Microsoft_Default 'Microsoft.CognitiveServices/accounts/raiPolicies@2025-06-01' = {
  parent: accounts_icewolf_aishell_01_name_resource
  name: 'Microsoft.Default'
  properties: {
    mode: 'Blocking'
    contentFilters: [
      {
        name: 'Hate'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Hate'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Sexual'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Sexual'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Violence'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Violence'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Selfharm'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Selfharm'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
    ]
  }
}

resource accounts_icewolf_aishell_01_name_Microsoft_DefaultV2 'Microsoft.CognitiveServices/accounts/raiPolicies@2025-06-01' = {
  parent: accounts_icewolf_aishell_01_name_resource
  name: 'Microsoft.DefaultV2'
  properties: {
    mode: 'Blocking'
    contentFilters: [
      {
        name: 'Hate'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Hate'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Sexual'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Sexual'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Violence'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Violence'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Selfharm'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Selfharm'
        severityThreshold: 'Medium'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Jailbreak'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'Protected Material Text'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'Protected Material Code'
        blocking: false
        enabled: true
        source: 'Completion'
      }
    ]
  }
}
