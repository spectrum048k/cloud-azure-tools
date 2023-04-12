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

# Configure the Azure Active Directory Provider
provider "azuread" {
}

resource "azuread_group" "group" {
  for_each = var.groups

  display_name            = each.value.name
  security_enabled        = true
  description             = each.value.description
  prevent_duplicate_names = true
}