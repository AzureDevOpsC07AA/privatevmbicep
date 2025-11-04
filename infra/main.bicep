
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string


@minLength(1)
@description('Primary location for all resources')
param location string

@secure()
@description('Password for the Windows VM')
param winVMPassword string //no value specified, so user will get prompted for it during deployment


var tags = {
  'azd-env-name': environmentName
  CostControl:'Ignore'
  SecurityControl: 'Ignore'
}


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}


module vmModule './sqlvm.bicep' = {
  name: 'deploySqlVM'
  params: {
    vmName: 'sqlvm'
    adminUsername: 'vmadmin'
    adminPassword: winVMPassword
  }
  scope: rg
}

module privateDns './private-dns.bicep' = {
  name: 'deployPrivateDns'
  params: {
    vnetId: vmModule.outputs.vnetId
  }
  scope: rg
}

module sqlServer 'sqlserver.bicep' = {
  name: 'deploySqlServer'
  scope: rg
  params: {
    location: location
    vmPrincipalId: vmModule.outputs.vmPrincipalId
  }
}

module privateEndpoints './private-endpoints.bicep' = {
  name: 'deployPrivateEndpoints'
  params: {
    location: location
    subnetId: vmModule.outputs.privateEndpointSubnetId
    sqlServerId: sqlServer.outputs.sqlServerId
    keyVaultId: sqlServer.outputs.keyVaultId
    sqlPrivateDnsZoneId: privateDns.outputs.sqlPrivateDnsZoneId
    kvPrivateDnsZoneId: privateDns.outputs.kvPrivateDnsZoneId
  }
  scope: rg
}

module vmKeyVaultConfig './sqlvm-keyvault-config.bicep' = {
  name: 'configureVMKeyVault'
  params: {
    vmPrincipalId: vmModule.outputs.vmPrincipalId
    keyVaultName: sqlServer.outputs.keyVaultName
    keyVaultFqdn: sqlServer.outputs.keyVaultFqdn
  }
  scope: rg
  dependsOn: [
    privateEndpoints
  ]
}
