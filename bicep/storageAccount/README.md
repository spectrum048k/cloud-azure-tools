# Storage Account Bicep Template

This template creates a secure Azure Storage Account with blob containers and network access controls.

## Features

- **Security-first configuration**:
  - HTTPS-only traffic enforcement
  - Shared key access disabled (Azure AD authentication only)
  - Minimum TLS 1.2 requirement
  - Network ACLs with IP restrictions
  - Private blob containers (no anonymous access)

- **Data protection**:
  - Blob versioning enabled
  - CORS configuration for web applications
  - Delete retention policy ready (currently disabled)

- **Flexible deployment**:
  - Multiple blob containers support
  - Configurable SKU options
  - IP allowlist for network access control

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `storageAccountName` | string | Yes | - | Name of the Storage Account (max 24 chars, lowercase) |
| `storageAccountSku` | string | No | `Standard_LRS` | Storage Account SKU (see allowed values below) |
| `location` | string | No | Resource Group location | Location for the storage account |
| `ipAllowList` | array | No | `[]` | Array of public IPs allowed to access storage account |
| `containerNames` | array | No | `[]` | Array of blob container names to create |

### Allowed SKU Values

- `Standard_LRS` - Locally redundant storage
- `Standard_GRS` - Geo-redundant storage  
- `Standard_RAGRS` - Read-access geo-redundant storage
- `Standard_ZRS` - Zone-redundant storage
- `Premium_LRS` - Premium locally redundant storage
- `Premium_ZRS` - Premium zone-redundant storage
- `Standard_GZRS` - Geo-zone-redundant storage
- `Standard_RAGZRS` - Read-access geo-zone-redundant storage

## Usage

### What-if deployment (preview changes)
```bash
az deployment group what-if \
  --resource-group <RG-NAME> \
  --template-file ./deploy.bicep \
  --parameters ./deploy.parameters.json
```

### Deploy storage account
```bash
az deployment group create \
  --resource-group <RG-NAME> \
  --template-file ./deploy.bicep \
  --parameters ./deploy.parameters.json
```

### Example with inline parameters
```bash
az deployment group create \
  --resource-group rg-prod-storage \
  --template-file ./deploy.bicep \
  --parameters storageAccountName="mystorageacct001" \
               storageAccountSku="Standard_GRS" \
               ipAllowList='["203.0.113.1","203.0.113.2"]' \
               containerNames='["documents","images","logs"]'
```

## Example Parameters File

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "mystorageaccount001"
    },
    "storageAccountSku": {
      "value": "Standard_GRS"
    },
    "ipAllowList": {
      "value": ["203.0.113.1", "203.0.113.2", "198.51.100.0/24"]
    },
    "containerNames": {
      "value": ["documents", "images", "backups", "logs"]
    }
  }
}
```

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storageAccountResourceId` | string | The resource ID of the deployed storage account |
| `name` | string | The name of the deployed storage account |

## Security Considerations

### Network Access
- **Default behavior**: If no IPs are specified in `ipAllowList`, the storage account allows access from all Azure services
- **Restricted access**: When IPs are specified, only those IPs and Azure services can access the storage account
- **IP format**: Supports both individual IPs (`203.0.113.1`) and CIDR ranges (`198.51.100.0/24`)

### Authentication
- **Shared key access disabled**: Only Azure AD authentication is allowed
- **Service principals**: Use managed identities or service principals for application access
- **User access**: Users must authenticate via Azure AD

### Data Protection
- **Encryption**: All data encrypted at rest (default Azure behavior)
- **Versioning**: Blob versioning enabled to protect against accidental overwrites
- **Container access**: All containers created with private access (no anonymous read)

## Common Use Cases

### Development Environment
```json
{
  "storageAccountName": {"value": "devstorageacct001"},
  "storageAccountSku": {"value": "Standard_LRS"},
  "ipAllowList": {"value": ["your.office.ip.here"]},
  "containerNames": {"value": ["dev-data", "test-uploads"]}
}
```

### Production Environment
```json
{
  "storageAccountName": {"value": "prodstorageacct001"},
  "storageAccountSku": {"value": "Standard_GRS"},
  "ipAllowList": {"value": ["prod.server.1", "prod.server.2", "backup.subnet/24"]},
  "containerNames": {"value": ["production-data", "backups", "logs", "reports"]}
}
```

### Public Web Application (with CORS)
The template includes CORS configuration allowing GET, POST, PUT methods from any origin. Modify the CORS settings in the template if you need more restrictive policies.

## Troubleshooting

### Common Issues

1. **Storage account name conflicts**
   - Names must be globally unique across all Azure
   - Use only lowercase letters and numbers
   - Maximum 24 characters

2. **Network access denied**
   - Verify your IP is in the `ipAllowList`
   - Check if you're accessing from an allowed Azure service
   - Confirm Azure AD authentication is configured

3. **Container creation fails**
   - Ensure container names follow Azure naming conventions
   - Names must be lowercase and contain only letters, numbers, and hyphens
   - Names must be 3-63 characters long

## Related Documentation

- [Azure Storage Account Documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Bicep Storage Account Reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep)
- [Storage Account Security Best Practices](https://docs.microsoft.com/en-us/azure/storage/blobs/security-recommendations)
