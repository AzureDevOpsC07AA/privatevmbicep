targetScope = 'resourceGroup'

param location string
param vmPrincipalId string

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'sql-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Application'
      login: 'sqlvm-managed-identity'
      sid: vmPrincipalId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Environment: 'Dev'
    Application: 'SQLWorkloadSim'
  }
}

// Security Center settings for SQL server
resource sqlServerSecurityAlertPolicy 'Microsoft.Sql/servers/securityAlertPolicies@2022-05-01-preview' = {
  name: 'Default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    emailAddresses: []
    emailAccountAdmins: false
    retentionDays: 0
  }
}

// Azure Defender for SQL
resource sqlServerAdvancedThreatProtection 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2022-05-01-preview' = {
  name: 'Default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
  }
}

// Server-level audit settings
resource sqlServerAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2022-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 90
  }
}

// Firewall rules removed - using private endpoint instead

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: 'AdventureWorksLT'
  parent: sqlServer
  location: location
  properties: {
    sampleName: 'AdventureWorksLT' // This deploys the sample database
    maxSizeBytes: 2147483648 // 2 GB, adjust if needed
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
    capacity: 20
  }
}

output sqlServerName string = sqlServer.name
output sqlServerId string = sqlServer.id
// output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'myKeyVault${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

var sqlConnectionString = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=AdventureWorksLT;Authentication=ActiveDirectoryManagedIdentity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

resource sqlConnSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'AdventureWorksLT-ConnectionString'
  properties: {
    value: sqlConnectionString
  }
}

// output keyvault name
output keyVaultName string = keyVault.name
//output keyvaltsecretUri string = sqlConnSecret.properties.secretUri
output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
//output sqlconnSecret secret name
output sqlConnSecretName string = sqlConnSecret.name
// output keyvault fqdn
output keyVaultFqdn string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id



