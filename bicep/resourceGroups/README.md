# Resource Groups Bicep Template

To use add a custom parameter files to a parameters directory.

## Resource Groups

This template creates one or more Azure Resource Groups at the subscription level.

See the [bicep definition here](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?pivots=deployment-language-bicep)

### What-if deployment (preview changes)
```sh
az deployment sub what-if --template-file .\deploy.bicep --parameters .\deploy.parameters.json --location <LOCATION>
```

### Deploy resource groups
```sh
az deployment sub create --template-file .\deploy.bicep --parameters .\deploy.parameters.json --location <LOCATION>
```

### Example usage
```sh
# Preview what resource groups would be created
az deployment sub what-if --template-file .\deploy.bicep --parameters .\deploy.parameters.json --location eastus

# Actually deploy the resource groups
az deployment sub create --template-file .\deploy.bicep --parameters .\deploy.parameters.json --location eastus
```

## Parameters

- `names`: Array of resource group names to create
- `location`: Location for the resource groups (optional, defaults to deployment location)
- `tags`: Tags to apply to all resource groups (optional)