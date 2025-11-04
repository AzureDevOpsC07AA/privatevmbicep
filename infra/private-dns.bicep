targetScope = 'resourceGroup'

param vnetId string

// Private DNS Zone for SQL Server
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  properties: {}
}

// Private DNS Zone for Key Vault
resource kvPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.keyvaultDns}'
  location: 'global'
  properties: {}
}

// Link SQL Private DNS Zone to VNet
resource sqlPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: 'sql-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Link Key Vault Private DNS Zone to VNet
resource kvPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: kvPrivateDnsZone
  name: 'kv-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output sqlPrivateDnsZoneId string = sqlPrivateDnsZone.id
output kvPrivateDnsZoneId string = kvPrivateDnsZone.id
