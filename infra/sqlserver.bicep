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
output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName

