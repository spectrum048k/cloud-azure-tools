# IPAM Azure VNet IP Address Utility

This module provides functions to:
- Query an Azure Virtual Network (VNet) and return the number of available IP addresses in that VNet.
- Suggest an available IP range for a new subnet of specified size in the VNet.

## Prerequisites
- Python 3.7+
- Azure SDK for Python (`azure-identity`, `azure-mgmt-network`)
- Azure credentials configured (e.g., via `az login` or environment variables)

## Installation
Install required packages:

Set your Azure subscription ID as an environment variable:

```bash
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
# Optional for service principal authentication:
export AZURE_TENANT_ID="<your-tenant-id>"
export AZURE_CLIENT_ID="<your-client-id>"
export AZURE_CLIENT_SECRET="<your-client-secret>"
```

See `test_vnet_ipam.py` for example usage.

## Function Reference
### get_available_ips_in_vnet(subscription_id: str, resource_group: str, vnet_name: str) -> int
- **subscription_id**: Azure subscription ID
- **resource_group**: Resource group name
- **vnet_name**: VNet name
- **Returns**: Number of available IP addresses in the VNet

### get_available_subnet_range(subscription_id: str, resource_group: str, vnet_name: str, subnet_size: int) -> str
- **subscription_id**: Azure subscription ID
- **resource_group**: Resource group name
- **vnet_name**: VNet name
- **subnet_size**: Number of IP addresses required for the new subnet (minimum 8)
- **Returns**: Available CIDR block for the new subnet or error message if insufficient space

## Notes
- The functions account for Azure-reserved IPs and validate minimum subnet size (/29, 8 IPs).
- Ensure your credentials have permission to read network resources.
- The subnet suggestion function will find available ranges, including gaps between existing subnets.
