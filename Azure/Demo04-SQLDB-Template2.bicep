//Microsoft.Sql servers
//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers?tabs=bicep

resource symbolicname 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: 'string'
  location: 'string'
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  identity: {
    type: 'string'
    userAssignedIdentities: {}
  }
  properties: {
    administratorLogin: 'string'
    administratorLoginPassword: 'string'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: bool
      login: 'string'
      principalType: 'string'
      sid: 'string'
      tenantId: 'string'
    }
    federatedClientId: 'string'
    keyId: 'string'
    minimalTlsVersion: 'string'
    primaryUserAssignedIdentityId: 'string'
    publicNetworkAccess: 'string'
    restrictOutboundNetworkAccess: 'string'
    version: 'string'
  }
}

//Microsoft.Sql servers/firewallRules
//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/firewallrules?tabs=bicep
resource symbolicname 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  name: 'string'
  parent: resourceSymbolicName
  properties: {
    endIpAddress: 'string'
    startIpAddress: 'string'
  }
}


//Microsoft.Sql servers/databases
//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases?tabs=bicep
resource symbolicname 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  name: 'string'
  location: 'string'
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  sku: {
    capacity: int
    family: 'string'
    name: 'string'
    size: 'string'
    tier: 'string'
  }
  parent: resourceSymbolicName
  identity: {
    delegatedResources: {}
    type: 'string'
    userAssignedIdentities: {}
  }
  properties: {
    autoPauseDelay: int
    catalogCollation: 'string'
    collation: 'string'
    createMode: 'string'
    elasticPoolId: 'string'
    federatedClientId: 'string'
    highAvailabilityReplicaCount: int
    isLedgerOn: bool
    licenseType: 'string'
    longTermRetentionBackupResourceId: 'string'
    maintenanceConfigurationId: 'string'
    maxSizeBytes: int
    minCapacity: json('decimal-as-string')
    primaryDelegatedIdentityClientId: 'string'
    readScale: 'string'
    recoverableDatabaseId: 'string'
    recoveryServicesRecoveryPointId: 'string'
    requestedBackupStorageRedundancy: 'string'
    restorableDroppedDatabaseId: 'string'
    restorePointInTime: 'string'
    sampleName: 'string'
    secondaryType: 'string'
    sourceDatabaseDeletionDate: 'string'
    sourceDatabaseId: 'string'
    zoneRedundant: bool
  }
}
