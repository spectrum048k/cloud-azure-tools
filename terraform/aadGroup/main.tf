# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group

# Configure Terraform
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

# variables
variable "group_names" {
  type        = list(string)
  description = "List of Azure AD group names"
  default     = []
}

# Configure the Azure Active Directory Provider
provider "azuread" {
}

data "azuread_client_config" "current" {}

# NB: array variables not usuable in prod as group is linked to array index
resource "azuread_group" "group" {
  count                   = length(var.group_names)
  display_name            = var.group_names[count.index]
  owners                  = [data.azuread_client_config.current.object_id]
  security_enabled        = true
  description             = "group created by terraform aad provider"
  prevent_duplicate_names = true
}

output "group_id" {
  value = azuread_group.group.*.id
}