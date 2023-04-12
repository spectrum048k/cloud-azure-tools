output "group_id" {
  value = values(azuread_group.group).*.id
}