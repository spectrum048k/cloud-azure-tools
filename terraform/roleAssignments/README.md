# Role Assignments

## tfvars

```
role_assignment = {
 "role1" = {
    resource_group_name  = "resource-group1"
    role_definition_id   = "role-definition-id1"
    user_name         = ""
  }
  "role2" = {
    resource_group_name  = "resource-group2"
    role_definition_id   = "role-definition-id2"
    user_name         = ""
  }
}
```

## backend.tf

```
terraform {
  backend "azurerm" {
    resource_group_name  = "resource-group-name"
    storage_account_name = "storageaccountname"
    container_name       = "container_name"
    key                  = "terraform.tfstate"
  }
}
```
