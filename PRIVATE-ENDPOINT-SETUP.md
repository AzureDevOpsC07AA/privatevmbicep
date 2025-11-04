# Private Endpoint Configuration for SQL Workload Simulator

## Overview
The infrastructure has been updated to use private endpoints for secure connectivity between the VM and both SQL Server and Key Vault resources. This configuration eliminates public internet exposure and provides enhanced security.

## Architecture Changes

### 1. Network Infrastructure
- **Virtual Network**: Extended with additional subnet for private endpoints
  - Main subnet: `10.0.0.0/24` (for VM)
  - Private endpoint subnet: `10.0.1.0/24` (for private endpoints)
  - Private endpoint network policies disabled on PE subnet

### 2. Private DNS Zones
- **SQL Server DNS Zone**: `privatelink${environment().suffixes.sqlServerHostname}`
- **Key Vault DNS Zone**: `privatelink${environment().suffixes.keyvaultDns}`
- Both zones are linked to the VNet for automatic DNS resolution

### 3. SQL Server Configuration
- **Public Network Access**: Disabled
- **Firewall Rules**: Removed (no longer needed)
- **Azure AD Authentication**: Continues to use VM's managed identity
- **Private Endpoint**: Created in dedicated subnet with DNS integration

### 4. Key Vault Configuration
- **Public Network Access**: Disabled
- **Network ACLs**: Default action set to 'Deny'
- **Private Endpoint**: Created in dedicated subnet with DNS integration

### 5. Virtual Machine Changes
- **Public IP**: Removed (VM is now purely private)
- **Network Security Groups**: Retained for additional security
- **Connectivity**: Uses private endpoints only

## Security Benefits

1. **Network Isolation**: All communication stays within the Azure backbone
2. **No Internet Exposure**: SQL Server and Key Vault are not accessible from public internet
3. **DNS Resolution**: Private DNS zones ensure proper name resolution to private IP addresses
4. **Zero Trust**: VM can only access resources through designated private endpoints

## Files Modified

### New Files Created:
- `infra/private-dns.bicep` - Private DNS zones and VNet links
- `infra/private-endpoints.bicep` - Private endpoint resources with DNS integration

### Modified Files:
- `infra/main.bicep` - Added private DNS and endpoints modules, removed public IP
- `infra/sqlvm.bicep` - Added private endpoint subnet, removed public IP
- `infra/sqlserver.bicep` - Disabled public access, removed firewall rules

## Deployment Notes

### Prerequisites
- The VM will no longer have direct internet access
- Remote access will need to be configured separately (e.g., via Azure Bastion, VPN, or ExpressRoute)

### Connection Strings
- SQL Server connections will continue to use the same FQDN
- Private DNS resolution will automatically route to private IP addresses
- Key Vault URLs remain the same with private resolution

### Testing Connectivity
After deployment, verify private connectivity from the VM:
```powershell
# Test SQL Server connectivity
nslookup your-sql-server.database.windows.net

# Test Key Vault connectivity  
nslookup your-key-vault.vault.azure.net
```

Both should resolve to private IP addresses in the 10.0.1.x range.

## Next Steps

1. **Deploy the updated infrastructure** using Azure Developer CLI
2. **Configure access method** for VM management (Bastion, VPN, etc.)
3. **Verify application connectivity** to SQL Server and Key Vault
4. **Monitor private endpoint metrics** in Azure Monitor

## Security Compliance
This configuration aligns with:
- Azure Security Benchmark recommendations
- Zero Trust network principles  
- Private networking best practices
- Data residency and sovereignty requirements