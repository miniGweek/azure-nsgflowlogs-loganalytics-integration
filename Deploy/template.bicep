//targetScope = 'subscription'
param resourceGroupName string
param resourceGroupLocation string
param appServicePlan_name string
param functionName string
param functionLocation string
param functionStorageAccount string
param blobTriggerTargetStorageAccountConnectionString string
param loganalyticsWorkspaceId string
param loganalyticsWorkspaceKey string

// resource resourceGroupName_resource 'Microsoft.Resources/resourceGroups@2019-10-01' = {
//   name: resourceGroupName
//   location: resourceGroupLocation
// }

module functuinWithBlobTrigger './functionwithBlobTrigger.bicep' = {
  name: '${resourceGroupName}Deployment${uniqueString(concat(functionName, subscription().subscriptionId))}'
  scope: resourceGroup(resourceGroupName)
  params: {
    resourceGroupName: resourceGroupName
    resourceGroupLocation: resourceGroupLocation
    functionName: functionName
    appServicePlan_name: appServicePlan_name
    functionLocation: functionLocation
    functionStorageAccount: functionStorageAccount
    blobTriggerTargetStorageAccountConnectionString: blobTriggerTargetStorageAccountConnectionString
    loganalyticsWorkspaceId: loganalyticsWorkspaceId
    loganalyticsWorkspaceKey: loganalyticsWorkspaceKey
  }
}
