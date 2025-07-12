
resource "azurerm_resource_provider_registration" "resource_providers" {
  for_each = { for name in var.resource_provider_names : name => name }
  name     = each.value
}