param vmName string
param adminUsername string
@secure()
param adminPassword string
param location string = resourceGroup().location

param bacpacStorageUrl string
param targetSqlServer string
param targetDb string
param sqlAdmin string
@secure()
param sqlPassword string

// Create VNet
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
        }
      }
    ]
  }
}

// Create Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Create Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2019-WS2019'
        sku: 'Standard'
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

// Custom script to import .bacpac
resource scriptExt 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://github.com/koenraadhaedens/azd-sqlworloadsim/blob/856d204055b1a3b8342ea590f64bd901b65da2e5/infra/deploy-bacpac.ps1'
      ]
    }
    protectedSettings: {
            commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File deploy-bacpac.ps1 -BacpacUrl "${bacpacStorageUrl}" -SqlServer "${targetSqlServer}" -Database "${targetDb}" -SqlAdmin "${sqlAdmin}" -SqlPassword "${sqlPassword}"'
    }
  }
}
