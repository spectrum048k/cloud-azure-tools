targetScope = 'resourceGroup'

@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param storageAccountSku string = 'Standard_LRS'

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Array of public IPs allowed to access storage account. Leave empty to allow all Azure services.')
param ipAllowList array = []

@description('The name of the blob containers.')
param containerNames array = []

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      ipRules: [for ip in ipAllowList: {
        value: ip
        action: 'Allow'
      }]
      defaultAction: empty(ipAllowList) ? 'Allow' : 'Deny'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedHeaders: ['*']
          allowedMethods: ['GET', 'POST', 'PUT']
          allowedOrigins: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 86400
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: false
    }
    isVersioningEnabled:true
  }
}

resource containerResources 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = [for containerName in containerNames: {
  name: '${storageAccountName}/default/${containerName}'

  properties: {
    publicAccess: 'None'
  }
  
  dependsOn: [
    // Add dependency on blob service
    blobService
  ]
}]

@description('The resource ID of the deployed storage account.')
output storageAccountResourceId string = storageAccount.id

@description('The name of the deployed storage account.')
output name string = storageAccount.name

