param location string = resourceGroup().location
param sqlServerName string
param adminLogin string
@secure()
param adminPassword string
param firewallRuleName string = 'AllowVmPublicIp'
param vmPublicIp string

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
    startIpAddress: vmPublicIp
    endIpAddress: vmPublicIp
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

