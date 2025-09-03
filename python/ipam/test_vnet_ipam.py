import os
from azure_vnet_ipam import get_available_ips_in_vnet, get_available_subnet_range

if __name__ == "__main__":
    # Replace with your actual Azure details
    # Read subscription_id from environment variable
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID", "")
    resource_group = "rg-virtual-networks-01"
    vnet_name = "hub-vnet"

    if not subscription_id:
        print("Error: Please set the AZURE_SUBSCRIPTION_ID environment variable.")
    else:
        available_ips = get_available_ips_in_vnet(subscription_id, resource_group, vnet_name)
        print(f"Available IPs in VNet '{vnet_name}': {available_ips}")

        # Test new function for subnet range (using available_ips as requested size for demonstration)
        subnet_size =  8  # Use available_ips or minimum allowed
        subnet_range = get_available_subnet_range(subscription_id, resource_group, vnet_name, subnet_size)
        print(f"Suggested subnet range for size {subnet_size} in VNet '{vnet_name}': {subnet_range}")
