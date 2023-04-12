variable "groups" {
  description = "Groups to manage in terraform"
  type = map(object({
    name  = string
    description = string
  }))
}