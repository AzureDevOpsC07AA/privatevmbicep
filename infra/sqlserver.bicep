param location string = resourceGroup().location
param sqlServerName string
param adminLogin string
@secure()
param adminPassword string
param publicIpName string = 'vmPublicIp'
param firewallRuleName string = 'AllowVmPublicIp'

// Create Public IP for VM
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

// Add firewall rule to allow VM Public IP
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  parent: sqlServer
  name: firewallRuleName
  properties: {
    startIpAddress: publicIp.properties.ipAddress
    endIpAddress: publicIp.properties.ipAddress
  }
  dependsOn: [
    sqlServer
    publicIp
  ]
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output vmPublicIp string = publicIp.properties.ipAddress
