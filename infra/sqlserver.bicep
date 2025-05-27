targetScope = 'resourceGroup'

param location string
param sqlAdminUsername string
@secure()
param sqlAdminPassword string
param allowedIpAddress string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'mySqlServer${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowMyPublicIp'
  parent: sqlServer
  properties: {
    startIpAddress: allowedIpAddress
    endIpAddress: allowedIpAddress
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: 'AdventureWorksLT'
  parent: sqlServer
  location: location
  properties: {
    sampleName: 'AdventureWorksLT' // This deploys the sample database
    maxSizeBytes: 2147483648 // 2 GB, adjust if needed
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
    capacity: 20
  }
}

output sqlServerName string = sqlServer.name
// output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'myKeyVault${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

var sqlConnectionString = 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=AdventureWorksLT;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;'

resource sqlConnSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'AdventureWorksLT-ConnectionString'
  properties: {
    value: sqlConnectionString
  }
}

// output keyvault name
output keyVaultName string = keyVault.name
//output keyvaltsecretUri string = sqlConnSecret.properties.secretUri
output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
//output sqlconnSecret secret name
output sqlConnSecretName string = sqlConnSecret.name
// output keyvault fqdn
output keyVaultFqdn string = keyVault.properties.vaultUri



