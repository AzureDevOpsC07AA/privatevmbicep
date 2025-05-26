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

output sqlServerName string = sqlServer.name
