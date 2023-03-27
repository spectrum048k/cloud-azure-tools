
provider "azurerm" {
  features {}
}

data "azurerm_subscription" "main" {
}

resource "azurerm_role_definition" "custom_role" {
  name               = "tf-custom-role-definition-01"
  scope              = data.azurerm_subscription.main.id

  permissions {
    actions     = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.main.id,
  ]
}

output "role_id" {
  value = azurerm_role_definition.custom_role.id
}