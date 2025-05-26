targetScope = 'resourceGroup'

param location string

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'myPublicIp'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output ipAddress string = publicIp.properties.ipAddress
output publicIpResourceId string = publicIp.id
