param resourceGroupName string
param resourceGroupLocation string
param appServicePlan_name string
param functionName string
param functionLocation string
param functionStorageAccount string
param blobTriggerTargetStorageAccountConnectionString string
param loganalyticsWorkspaceId string
param loganalyticsWorkspaceKey string

resource storage_name 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  location: resourceGroupLocation
  name: functionStorageAccount
  properties: {
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
}
resource appServicePlan_resource 'Microsoft.Web/serverfarms@2018-11-01' = {
  location: resourceGroupLocation
  name: appServicePlan_name
  kind: 'linux'
  properties: {
    name: appServicePlan_name
    workerSize: 0
    workerSizeId: 0
    numberOfWorkers: 1
    reserved: true
  }
  sku: {
    Tier: 'Basic'
    Name: 'B1'
  }
}

resource functionapp_resource 'Microsoft.Web/sites@2020-12-01' = {
  location: functionLocation
  name: functionName
  tags: {
    'hidden-related:${appServicePlan_resource.id}': 'empty'
  }
  kind: 'functionapp,linux'
  properties: {
    httpsOnly: true
    reserved: false
    serverFarmId: appServicePlan_resource.id
    clientAffinityEnabled: false
    siteConfig: {
      use32BitWorkerProcess: false
      linuxFxVersion: 'dotnet|3.1'
      alwaysOn: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    appServicePlan_resource
    storage_name
  ]
}

resource functionapp_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: functionapp_resource
  name: 'appsettings'
  location: functionLocation
  properties: {
    AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccount};AccountKey=${listKeys(storage_name.id, '2017-10-01').keys[0].value};EndpointSuffix=core.windows.net'
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccount};AccountKey=${listKeys(storage_name.id, '2017-10-01').keys[0].value};EndpointSuffix=core.windows.net'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    nsgflowlog_STORAGE: blobTriggerTargetStorageAccountConnectionString
    loganalyticsWorkspaceId: loganalyticsWorkspaceId
    loganalyticsWorkspaceKey: loganalyticsWorkspaceKey
    WEBSITE_RUN_FROM_PACKAGE: '1'
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'false'
  }
  dependsOn: [
    functionapp_resource
  ]
}
