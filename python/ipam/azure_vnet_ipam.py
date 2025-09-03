def get_available_subnet_range(subscription_id: str, resource_group: str, vnet_name: str, subnet_size: int) -> str:
    """
    Returns an available IP range (CIDR) for a new subnet of the specified size in the VNet.
    If insufficient address space, returns an error message.
    Args:
        subscription_id (str): Azure subscription ID
        resource_group (str): Resource group name
        vnet_name (str): VNet name
        subnet_size (int): Number of IP addresses required for the new subnet
    Returns:
        str: Available CIDR block for the new subnet or error message
    """
    # Azure minimum subnet size is /29 (8 IPs)
    MIN_SUBNET_SIZE = 8
    if subnet_size < MIN_SUBNET_SIZE:
        return f"Error: Minimum subnet size is {MIN_SUBNET_SIZE} IP addresses (/29). Requested: {subnet_size}."

    credential = DefaultAzureCredential()
    network_client = NetworkManagementClient(credential, subscription_id)
    vnet = network_client.virtual_networks.get(resource_group, vnet_name)
    import ipaddress
    vnet_prefixes = vnet.address_space.address_prefixes
    # Collect all used subnets
    used_networks = []
    if hasattr(vnet, 'subnets') and vnet.subnets:
        for subnet in vnet.subnets:
            address_prefix = subnet.address_prefix
            if "," in address_prefix:
                prefixes = address_prefix.split(",")
            else:
                prefixes = [address_prefix]
            for prefix in prefixes:
                used_networks.append(ipaddress.ip_network(prefix))

    # For each VNet address space, find a free range
    for vnet_prefix in vnet_prefixes:
        vnet_net = ipaddress.ip_network(vnet_prefix)
        # Find all possible subnets of the required size
        for candidate in vnet_net.subnets(new_prefix=ipaddress.ip_network(f"0.0.0.0/{32 - (subnet_size-1).bit_length()}").prefixlen):
            # Check if candidate overlaps with any used subnet
            if not any(candidate.overlaps(used) for used in used_networks):
                if candidate.num_addresses >= subnet_size:
                    return str(candidate)
    return f"Error: Insufficient address space in VNet for a subnet of size {subnet_size}."
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient


def get_available_ips_in_vnet(subscription_id: str, resource_group: str, vnet_name: str) -> int:
    """
    Query an Azure VNet and return the number of available IP addresses in that VNet.
    Args:
        subscription_id (str): Azure subscription ID
        resource_group (str): Resource group name
        vnet_name (str): VNet name
    Returns:
        int: Number of available IP addresses in the VNet
    """
    credential = DefaultAzureCredential()
    network_client = NetworkManagementClient(credential, subscription_id)
    vnet = network_client.virtual_networks.get(resource_group, vnet_name)
    import ipaddress
    # Calculate total IPs in VNet address space
    vnet_prefixes = vnet.address_space.address_prefixes
    total_vnet_ips = 0
    for vnet_prefix in vnet_prefixes:
        net = ipaddress.ip_network(vnet_prefix)
        total_vnet_ips += net.num_addresses

    # Calculate all IPs allocated to subnets
    allocated_ips = 0
    if hasattr(vnet, 'subnets') and vnet.subnets:
        for subnet in vnet.subnets:
            address_prefix = subnet.address_prefix
            if "," in address_prefix:
                prefixes = address_prefix.split(",")
            else:
                prefixes = [address_prefix]
            for prefix in prefixes:
                net = ipaddress.ip_network(prefix)
                allocated_ips += net.num_addresses

    # Available IPs are those not allocated to subnets
    available_ips = total_vnet_ips - allocated_ips
    return max(available_ips, 0)
