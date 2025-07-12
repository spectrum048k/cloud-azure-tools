# Bicep Samples

To use add custom parameter files to the parameters directory.

## Role Assignments

See the [role assignment documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac) and the [bicep definition here](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep)

### What-if deployment (preview changes)
```sh
az deployment group what-if --resource-group <RG-NAME> --template-file .\deploy.bicep --parameters .\deploy.parameters.json
```

### Deploy role assignments
```sh
az deployment group create --resource-group <RG-NAME> --template-file .\deploy.bicep --parameters .\deploy.parameters.json
```

### Example usage
```sh
# Preview what role assignments would be created
az deployment group what-if --resource-group rg-prod-web --template-file .\deploy.bicep --parameters .\deploy.parameters.json

# Actually deploy the role assignments
az deployment group create --resource-group rg-prod-web --template-file .\deploy.bicep --parameters .\deploy.parameters.json
```