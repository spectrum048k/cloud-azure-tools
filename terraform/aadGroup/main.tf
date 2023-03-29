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

variable "groups" {
  type = map
}

# Configure the Azure Active Directory Provider
provider "azuread" {
}

data "azuread_client_config" "current" {}

resource "azuread_group" "group" {
  for_each = var.groups

  display_name            = each.value
  owners                  = [data.azuread_client_config.current.object_id]
  security_enabled        = true
  description             = "group created by terraform aad provider"
  prevent_duplicate_names = true
}

output "group_id" {
  value = values(azuread_group.group).*.id
}