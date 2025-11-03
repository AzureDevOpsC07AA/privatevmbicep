
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
}


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}


module publicIp 'publicip.bicep' = {
  name: 'deployPublicIp'
  scope: rg
  params: {
    location: location
  }
}

module vmModule './sqlvm.bicep' = {
  name: 'deploySqlVM'
  params: {
    vmName: 'sqlvm'
    adminUsername: 'vmadmin'
    adminPassword: winVMPassword
    publicIpId: publicIp.outputs.publicIpResourceId
  }
  scope: rg
}

module sqlServer 'sqlserver.bicep' = {
  name: 'deploySqlServer'
  scope: rg
  params: {
    location: location
    allowedIpAddress: publicIp.outputs.ipAddress
    vmPrincipalId: vmModule.outputs.vmPrincipalId
  }
}

module vmKeyVaultConfig './sqlvm-keyvault-config.bicep' = {
  name: 'configureVMKeyVault'
  params: {
    vmPrincipalId: vmModule.outputs.vmPrincipalId
    keyVaultName: sqlServer.outputs.keyVaultName
    keyVaultFqdn: sqlServer.outputs.keyVaultFqdn
  }
  scope: rg
}
