# declare variables
variable "resource_group_name" {
  type        = string
  description = "Name of an existing resource group"
}

provider "azurerm" {
  features {}
}

# lookup required values
data "azurerm_resource_group" "nsg_rg" {
  name     = var.resource_group_name
}

# Create a new network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = data.azurerm_resource_group.nsg_rg.location
  resource_group_name = data.azurerm_resource_group.nsg_rg.name

  # Define the security rules for the NSG
  security_rule {
    name                       = "allow_ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
