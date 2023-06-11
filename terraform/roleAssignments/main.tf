terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

# use the resource group name to lookup the resource group id
data "azurerm_resource_group" "rg" {
  for_each = var.role_assignment
  name     = each.value.resource_group_name
}

# use the user name to lookup the user id
data "azuread_user" "users" {
  for_each = var.role_assignment
  user_principal_name = each.value.user_name
}

# use the role name to lookup the role definition id
# NB: this only seems to work for builtin roles

# data "azurerm_role_definition" "roles" {
#   for_each = var.role_assignment
#   name = each.value.role_name
# }

resource "azurerm_role_assignment" "assignments" {
  for_each           = var.role_assignment
  scope              = data.azurerm_resource_group.rg[each.key].id
  # role_definition_id = data.azurerm_role_definition.roles[each.key].id
  role_definition_id = each.value.role_definition_id
  principal_id       = data.azuread_user.users[each.key].id
}
