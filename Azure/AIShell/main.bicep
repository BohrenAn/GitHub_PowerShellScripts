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
