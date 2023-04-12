# Terraform Azure AD Groups

```sh
terraform apply -var-file=terraform.tfvars
```

## sample parameters.tfvars

```
groups = {
  "g1" = {
    name = "grp_tf_01"
    description = "created by terraform"
  },
  "g2" = {
    name = "grp_tf_02"
    description = "created by terraform"
  }
  "g4" = {
    name = "grp_tf_05"
    description = "created by terraform"
  }
}

```

See the terraform [registry documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group)