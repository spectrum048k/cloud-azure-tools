import os
from azure_vnet_ipam import AzureVNetIPAM

if __name__ == "__main__":
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID", "")
    tenant_id = os.getenv("AZURE_TENANT_ID", None)
    client_id = os.getenv("AZURE_CLIENT_ID", None)
    client_secret = os.getenv("AZURE_CLIENT_SECRET", None)
    resource_group = "rg-virtual-networks-01"
    vnet_name = "hub-vnet"

    if not subscription_id:
        print("Error: Please set the AZURE_SUBSCRIPTION_ID environment variable.")
    else:
        ipam = AzureVNetIPAM(subscription_id, tenant_id, client_id, client_secret)
        available_ips = ipam.get_available_ips_in_vnet(resource_group, vnet_name)
        print(f"Available IPs in VNet '{vnet_name}': {available_ips}")

        subnet_size = 8  # Minimum allowed
        subnet_range = ipam.get_available_subnet_range(resource_group, vnet_name, subnet_size)
        print(f"Suggested subnet range for size {subnet_size} in VNet '{vnet_name}': {subnet_range}")
