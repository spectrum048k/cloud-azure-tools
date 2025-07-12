targetScope = 'subscription'
@description('Required. The name of the Resource Group.')
param names array

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location

@description('Optional. Tags of the storage account resource.')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = [for name in names: {
  name: name 
  location: location
  tags: tags
}]

output resourceGroups array = [for (name, i) in names: {
  name: resourceGroup[i].name
  id: resourceGroup[i].id
  location: resourceGroup[i].location
}]
