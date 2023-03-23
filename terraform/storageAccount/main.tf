variable "resource_group_name" {
  type        = string
  description = "Name of an existing resource group"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "storage_account_tier" {
  type        = string
  description = "Performance tier for the storage account"
  default     = "Standard"
}

variable "storage_account_replication_type" {
  type        = string
  description = "Replication type for the storage account"
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Not an allowed default value"
  }
}

variable "ipAllowList" {
  type        = list(string)
  description = "Optional. Allow list of public IPs allowed to access storage account."
  default     = []
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "sa" {
  name                      = var.storage_account_name
  resource_group_name       = data.azurerm_resource_group.rg.name
  location                  = data.azurerm_resource_group.rg.location
  account_tier              = var.storage_account_tier
  account_replication_type  = var.storage_account_replication_type
  enable_https_traffic_only = true
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.ipAllowList
  }
}

output "storage_account_id" {
  value = azurerm_storage_account.sa.id
  description = "The resource ID of the deployed storage account."
}