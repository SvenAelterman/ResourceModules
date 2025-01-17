targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.containerinstance.containergroups-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'cicgecr'

@description('Generated. Used as a basis for unique resource names.')
param baseTime string = utcNow('u')

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
    managedIdentityName: 'dep-<<namePrefix>>-msi-${serviceShort}'
    // Adding base time to make the name unique as purge protection must be enabled (but may not be longer than 24 characters total)
    keyVaultName: 'dep-<<namePrefix>>-kv-${serviceShort}-${substring(uniqueString(baseTime), 0, 3)}'
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
    lock: 'CanNotDelete'
    containers: [
      {
        name: '<<namePrefix>>-az-aci-x-001'
        properties: {
          command: []
          environmentVariables: []
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports: [
            {
              port: '80'
              protocol: 'Tcp'
            }
            {
              port: '443'
              protocol: 'Tcp'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 2
            }
          }
        }
      }
      {
        name: '<<namePrefix>>-az-aci-x-002'
        properties: {
          command: []
          environmentVariables: []
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports: [
            {
              port: '8080'
              protocol: 'Tcp'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 2
            }
          }
        }
      }
    ]
    ipAddressPorts: [
      {
        protocol: 'Tcp'
        port: 80
      }
      {
        protocol: 'Tcp'
        port: 443
      }
    ]
    systemAssignedIdentity: true
    userAssignedIdentities: {
      '${resourceGroupResources.outputs.managedIdentityResourceId}': {}
    }
    cMKKeyName: resourceGroupResources.outputs.keyVaultEncryptionKeyName
    cMKKeyVaultResourceId: resourceGroupResources.outputs.keyVaultResourceId
  }
}
