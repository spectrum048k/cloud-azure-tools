output "role_assignment_ids" {
  value = [for id in azurerm_role_assignment.assignments: id.id]
}