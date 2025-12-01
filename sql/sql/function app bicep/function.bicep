// ============================================
// FUNCTION APP MODULE
// Location: Infrastructure/NDR/Bicep/Bridge/modules/Compute/functionApp.bicep
// ============================================

// Parameters
@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Function App')
param functionAppName string

@description('.NET Framework version')
param functionAppDotnetFrameworkVersion string = 'v10.0'

@description('Name of the resource group containing the virtual network')
param functionAppVirtualNetworkResourceGroupName string

@description('Name of the virtual network')
param functionAppVirtualNetworkName string

@description('Name of the subnet for VNet integration')
param functionAppSubnetName string

@description('Name of the subnet for private endpoint')
param functionAppPrivateEndpointSubnetName string

@description('Client ID of the user-assigned managed identity')
param functionAppUserAssignedManagedIdentityClientId string

@description('Resource ID of the user-assigned managed identity')
param functionAppUserAssignedIdentityId string

@description('Resource ID of the App Service Plan')
param functionAppPlanId string

@description('Minimum elastic instance count')
param functionAppMinimumElasticInstanceCount int = 1

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Tags for resources')
param tags object = {}

// ============================================
// EXISTING RESOURCES REFERENCES
// ============================================

// Existing Virtual Network
resource function_app_vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  scope: resourceGroup(functionAppVirtualNetworkResourceGroupName)
  name: functionAppVirtualNetworkName
}

// Existing Subnet for VNet Integration
resource function_app_subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: functionAppSubnetName
  parent: function_app_vnet
}

// Existing Subnet for Private Endpoint
resource private_endpoint_subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: functionAppPrivateEndpointSubnetName
  parent: function_app_vnet
}

// ============================================
// FUNCTION APP
// ============================================

resource function_app 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${functionAppUserAssignedIdentityId}': {}
    }
  }
  properties: {
    enabled: true
    serverFarmId: functionAppPlanId
    virtualNetworkSubnetId: function_app_subnet.id
    httpsOnly: true
    keyVaultReferenceIdentity: functionAppUserAssignedIdentityId
    publicNetworkAccess: 'Disabled'
    vnetRouteAllEnabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        hostType: 'Standard'
        sslState: 'Disabled'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        hostType: 'Repository'
        sslState: 'Disabled'
      }
    ]
    siteConfig: {
      numberOfWorkers: 1
      minimumElasticInstanceCount: functionAppMinimumElasticInstanceCount
      alwaysOn: true
      use32BitWorkerProcess: false
      healthCheckPath: '/health'
      minTlsVersion: '1.3'
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: functionAppDotnetFrameworkVersion
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
      autoHealEnabled: true
      autoHealRules: {
        triggers: {
          privateBytesInKB: 0
          statusCodes: [
            {
              status: 401
              subStatus: 0
              win32Status: 0
              count: 20
              timeInterval: '00:01:00'
            }
          ]
          slowRequestsWithPath: []
          statusCodesRange: []
        }
        actions: {
          actionType: 'Recycle'
          minProcessExecutionTime: '00:00:00'
        }
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
          value: 'Authorization=AAD;ClientId=${functionAppUserAssignedManagedIdentityClientId}'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
}

// ============================================
// PUBLISHING CREDENTIALS POLICIES
// ============================================

// FTP Publishing Credentials
resource function_app_publishing_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  name: 'ftp'
  parent: function_app
  properties: {
    allow: true
  }
}

// SCM Publishing Credentials
resource function_app_publishing_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  name: 'scm'
  parent: function_app
  properties: {
    allow: true
  }
}

// ============================================
// PRIVATE ENDPOINT
// ============================================

resource function_app_private_endpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${functionAppName}-pe'
  tags: tags
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: functionAppName
        properties: {
          privateLinkServiceId: function_app.id
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${functionAppName}-nic'
    subnet: {
      id: private_endpoint_subnet.id
    }
  }
}

// ============================================
// OUTPUTS
// ============================================

output functionAppId string = function_app.id
output functionAppName string = function_app.name
output functionAppDefaultHostName string = function_app.properties.defaultHostName
output privateEndpointId string = function_app_private_endpoint.id
output privateEndpointName string = function_app_private_endpoint.name