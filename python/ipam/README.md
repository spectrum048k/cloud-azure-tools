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

```bash
pip install -r requirements.txt
```

## Usage

Set your Azure subscription ID as an environment variable:

```bash
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
```

Example usage:

```python
import os
from ipam.azure_vnet_ipam import get_available_ips_in_vnet, get_available_subnet_range

subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID", "")
resource_group = "<your-resource-group>"
vnet_name = "<your-vnet-name>"

available_ips = get_available_ips_in_vnet(subscription_id, resource_group, vnet_name)
print(f"Available IPs in VNet: {available_ips}")

# Suggest a subnet range for a new subnet of minimum size 8
subnet_size = 8
subnet_range = get_available_subnet_range(subscription_id, resource_group, vnet_name, subnet_size)
print(f"Suggested subnet range for size {subnet_size}: {subnet_range}")
```


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
