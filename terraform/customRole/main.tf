terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_definition" "cloud_workload_operator" {
  name  = "cr-cloud-workload-operator"
  scope = data.azurerm_subscription.primary.id

  permissions {
    actions = [
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/retrieveBootDiagnosticsData/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}

output "cloud_workload_operator_id" {
  value = azurerm_role_definition.cloud_workload_operator.id
}