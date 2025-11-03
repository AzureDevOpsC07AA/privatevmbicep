param vmName string
param adminUsername string
@secure()
param adminPassword string
param location string = resourceGroup().location
param publicIpId string 



// NSG for NIC
resource nicNsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: '${vmName}-nic-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'deny-rdp-nic'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// NSG for VNet/Subnet
resource vnetNsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: '${vmName}-vnet-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'deny-rdp-vnet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    networkSecurityGroup: {
      id: nicNsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
  }
}

// Update subnet inside VNet resource to reference NSG
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: vnetNsg.id
          }
        }
      }
    ]
  }
}


// Create Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
    identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ads_v6'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2022-WS2022'
        sku: 'Standard-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom script extension moved to separate module to handle dependencies properly

output vmPrincipalId string = vm.identity.principalId



// Key Vault access policy is now handled in a separate module


