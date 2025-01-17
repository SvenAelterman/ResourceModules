targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for a testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.network.azurefirewalls-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'nafhub'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

// =========== //
// Deployments //
// =========== //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module resourceGroupResources 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-paramNested'
  params: {
    virtualWanName: 'dep-<<namePrefix>>-vwan-${serviceShort}'
    virtualHubName: 'dep-<<namePrefix>>-vhub-${serviceShort}'
    firewallPolicyName: 'dep-<<namePrefix>>-afwp-${serviceShort}'
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name)}-test-${serviceShort}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: '<<namePrefix>>${serviceShort}001'
    firewallPolicyId: resourceGroupResources.outputs.firewallPolicyResourceId
    virtualHubId: resourceGroupResources.outputs.virtualHubResourceId
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
  }
}
