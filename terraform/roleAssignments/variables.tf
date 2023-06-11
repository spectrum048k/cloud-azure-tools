variable "role_assignment" {
  description = "Azure RBAC role assignment configuration"
  type        = map(object({
    resource_group_name  = string
    role_definition_id   = string
    user_name            = string
    # role_name            = string   NB: this only seems to work for builtin roles
  }))
}
