targetScope = 'resourceGroup'

param vmPrincipalId string
param keyVaultName string
param keyVaultFqdn string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource vmAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: vmPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource scriptExt 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'sqlvm/CustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/koenraadhaedens/azd-sqlworloadsim/refs/heads/main/infra/deploy-bacpac.ps1'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File deploy-bacpac.ps1 -KeyvaultFQDN "${keyVaultFqdn}"'
    }
  }
}
