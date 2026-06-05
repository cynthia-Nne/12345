// Parameters
@description('Location used to deploy resources')
param location string = resourceGroup().location

// UMI
param identities array
param dataSyncUmiName string

// Keyvault Parameters
param tenantId string
param keyvaultName string
param keyvaultVirtualNetworkResourceGroupName string
param keyvaultVirtualNetworkName string
param keyvaultPrivateEndpointSubnetName string
param KeyVaultAdminObjectId string
param KeyVaultEnableRbacAuthorization bool
param KeyVaultNetworkAclsBypass string
param KeyVaultNetworkAclsDefaultAction string
param skuName string
param servicePrincipal string

// Storage Account Parameters
param storageAccountName string
param functionAppStorageAccountName string
param storageAccountVirtualNetworkResourceGroupName string
param storageAccountVirtualNetworkName string
param storageAccountPrivateEndpointSubnetName string
param isHnsEnabled bool
param functionIsHnsEnabled bool
param StorageAccountRequiresDfsPrivateEndpoint bool
param publicNetworkAccess string
param isSftpEnabled bool

// Storage Encryption Key
param storageEncryptionKeyExpiryBaseDate string
param storageEncryptionKeyName string
param functionAppStorageEncryptionKeyExpiryBaseDate string
param functionAppStorageEncryptionKeyName string

// App Service Plan Parameters
param appServicePlanName string
param appServicePlanSkuTier string
param appServicePlanSkuName string
param appServicePlanCapacity int
param appServicePlanKind string
param appServicePlanPerSiteScaling bool
param appServicePlanZoneRedundant bool

// Log Analytics Workspace Parameters
param LogAnalyticsWorkspaceName string
param LogAnalyticsWorkspaceSku string
param LogAnalyticsWorkspaceRetentionDays int

// Application Insights Parameters
param appInsightsName string

// SQL Server Parameters
param sqlServerName string
param sqlServerAadAdminObjectId string
param sqlServerAdAdminLogin string
param sqlServerVersion string
param sqlServerMinimalTlsVersion string
param aadAdminType string
param azureADOnlyAuthentication bool
param sqlServerVirtualNetworkResourceGroupName string
param sqlServerVirtualNetworkName string
param sqlServerPrivateEndpointSubnetName string
param databases array
param sqlEncryptionKeyExpiryBaseDate string
param sqlEncryptionKeyName string

// Data Factory Parameters
param dataFactoryName string
param dataFactoryPublicNetworkAccess string
param dataFactoryVirtualNetworkResourceGroupName string
param dataFactoryVirtualNetworkName string
param dataFactoryPrivateEndpointSubnetName string
param dataFactoryEncryptionKeyExpiryBaseDate string
param dataFactoryEncryptionKeyName string

// Virtual Machine - SHIR
param virtualMachineNicSubnetResourceId string
param virtualMachineNicName string
param virtualMachineCount int
param virtualMachineName string
param virtualMachineZone string
param virtualMachineSize string
param virtualMachineDiskEncryptionSetId string
param virtualMachineAdminUsername string
@secure()
param virtualMachineAdminPassword string
param virtualMachineImageOS string
param virtualMachineImageOSVersion string

// SSH Key Parameters
param sshKeyName string
@secure()
param sshPublicKey string

// Resources
// UMI
module managedIdentities '../../../../bicep-modules/Bicep/modules/Security/userManagedIdentity.bicep' = {
  name: 'user-managed-identity'
  params: {
    location: location
    identities: identities
  }
}

var dataMigrationTargetUmiIndex = indexOf(map(identities, id => id.name), dataSyncUmiName)

// Existing ADF reference
resource existingAdf 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

// KeyVault
module KeyVault '../../../../bicep-modules/Bicep/modules/Security/keyVault.bicep' = {
  name: 'key-vault'
  params: {
    location: location
    keyvaultName: keyvaultName
    keyvaultVirtualNetworkResourceGroupName: keyvaultVirtualNetworkResourceGroupName
    keyvaultVirtualNetworkName: keyvaultVirtualNetworkName
    keyvaultPrivateEndpointSubnetName: keyvaultPrivateEndpointSubnetName
    tenantId: tenantId
    KeyVaultEnableRbacAuthorization: KeyVaultEnableRbacAuthorization
    KeyVaultNetworkAclsBypass: KeyVaultNetworkAclsBypass
    KeyVaultNetworkAclsDefaultAction: KeyVaultNetworkAclsDefaultAction
    skuName: skuName
    keyVaultAccessPolicy: [
      {
        objectId: KeyVaultAdminObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
      }
      {
        objectId: managedIdentities.outputs.objectIds[dataMigrationTargetUmiIndex]
        permissions: {
          certificates: []
          keys: [
            'unwrapKey'
            'wrapKey'
            'get'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: SqlServer.outputs.principalId
        permissions: {
          certificates: []
          keys: [
            'unwrapKey'
            'wrapKey'
            'get'
          ]
          secrets: []
          storage: []
        }
      }
      {
        objectId: servicePrincipal
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
      }
      {
        objectId: '2390271a-ff2c-4500-b5a0-1b296b81e80f'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: managedIdentities.outputs.objectIds[dataMigrationTargetUmiIndex]
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: 'c6ef2ab6-524e-46e0-9fdb-97900051d470'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '2188fe17-984c-4411-abda-37e2e97a19b6'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '3e957d7a-1be9-4f6d-aee3-17a1a4145984'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: 'cb9c29ae-9013-486f-ba0a-9fb9e589c1e9'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '060900de-07f8-403b-efb2-600e1ce19f4b'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '21c254e8-a090-465d-b717-c1f637f8cf87'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '97877c9e-e178-4cd2-8122-d2b3416cd034'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      {
        objectId: '94984078-5f49-45e6-a4ed-b63142f67b27'
        permissions: {
          certificates: [
            'Get'
            'List'
          ]
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
      // ADF System Identity
      {
        objectId: existingAdf.identity.principalId
        permissions: {
          certificates: []
          keys: [
            'Get'
            'List'
            'unwrapKey'
            'wrapKey'
          ]
          secrets: [
            'Get'
            'List'
          ]
          storage: []
        }
      }
    ]
    keyvaultPublicNetworkAccess: keyvaultPublicNetworkAccess
    tags: tags
  }
  dependsOn: [dataFactoryServer]
}

// Encryption key
module encryption '../../../../bicep-modules/Bicep/modules/Storage/createStorageEncryptionKey.bicep' = {
  name: 'storage-encryption-key'
  params: {
    storageKeyvaultName: keyvaultName
    storageEncryptionKeyExpiryBaseDate: storageEncryptionKeyExpiryBaseDate
    storageEncryptionKeyName: storageEncryptionKeyName
  }
  dependsOn: [KeyVault]
}

// Storage Account
module storageAccount '../../../../bicep-modules/Bicep/modules/Storage/storageAccount.bicep' = {
  name: 'storage-account'
  params: {
    storageAccountName: storageAccountName
    storageAccountVirtualNetworkResourceGroupName: storageAccountVirtualNetworkResourceGroupName
    storageAccountVirtualNetworkName: storageAccountVirtualNetworkName
    storageAccountPrivateEndpointSubnetName: storageAccountPrivateEndpointSubnetName
    storageAccountUserAssignedIdentityId: managedIdentities.outputs.identityResourceIds[dataMigrationTargetUmiIndex]
    storageAccountKeyvaultName: keyvaultName
    isHnsEnabled: isHnsEnabled
    StorageAccountRequiresDfsPrivateEndpoint: StorageAccountRequiresDfsPrivateEndpoint
    tags: tags
    StorageAccountEncryptionKeyName: storageEncryptionKeyName
    publicNetworkAccess: publicNetworkAccess
    isSftpEnabled: isSftpEnabled
    storageAccountAllowedIpAddresses: storageAccountAllowedIpAddresses
  }
}

// Function App Encryption key
module functionAppEncryption '../../../../bicep-modules/Bicep/modules/Storage/createStorageEncryptionKey.bicep' = {
  name: 'functionAppstorage-encryption-key'
  params: {
    storageKeyvaultName: keyvaultName
    storageEncryptionKeyExpiryBaseDate: functionAppStorageEncryptionKeyExpiryBaseDate
    storageEncryptionKeyName: functionAppStorageEncryptionKeyName
  }
  dependsOn: [KeyVault]
}

// Function App Storage Account
module functionAppStorageAccount '../../../../bicep-modules/Bicep/modules/Storage/storageAccount.bicep' = {
  name: 'functionAppstorage-account'
  params: {
    storageAccountName: functionAppStorageAccountName
    storageAccountVirtualNetworkResourceGroupName: storageAccountVirtualNetworkResourceGroupName
    storageAccountVirtualNetworkName: storageAccountVirtualNetworkName
    storageAccountPrivateEndpointSubnetName: storageAccountPrivateEndpointSubnetName
    storageAccountUserAssignedIdentityId: managedIdentities.outputs.identityResourceIds[dataMigrationTargetUmiIndex]
    storageAccountKeyvaultName: keyvaultName
    isHnsEnabled: functionIsHnsEnabled
    StorageAccountRequiresDfsPrivateEndpoint: StorageAccountRequiresDfsPrivateEndpoint
    tags: tags
    StorageAccountEncryptionKeyName: functionAppStorageEncryptionKeyName
    publicNetworkAccess: publicNetworkAccess
    isSftpEnabled: isSftpEnabled
    storageAccountAllowedIpAddresses: storageAccountAllowedIpAddresses
  }
}

// App Service Plan
module AppServicePlan '../../../../bicep-modules/Bicep/modules/Compute/appServicePlan.bicep' = {
  name: 'app-service-plan'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appServicePlanSkuTier: appServicePlanSkuTier
    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanCapacity: appServicePlanCapacity
    appServicePlanKind: appServicePlanKind
    appServicePlanPerSiteScaling: appServicePlanPerSiteScaling
    appServicePlanZoneRedundant: appServicePlanZoneRedundant
    tags: tags
  }
}

// Log Analytics Workspace
module logAnalyticsWorkspace '../../../../bicep-modules/Bicep/modules/Monitoring/logAnalyticsWorkspace.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    LogAnalyticsWorkspaceSku: LogAnalyticsWorkspaceSku
    LogAnalyticsWorkspaceRetentionDays: LogAnalyticsWorkspaceRetentionDays
    tags: tags
  }
}

// Application Insights
module applicationInsights '../../../../bicep-modules/Bicep/modules/Monitoring/applicationInsights.bicep' = {
  name: 'application-insights'
  params: {
    appInsightsName: appInsightsName
    LogAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.LogAnalyticsWorkspaceId
    tags: tags
  }
}

// Sql Server
module SqlServer '../../../../bicep-modules/Bicep/modules/Storage/sqlServer.bicep' = {
  name: 'sql-server'
  params: {
    location: location
    tenantId: tenantId
    sqlServerName: sqlServerName
    sqlServerAadAdminObjectId: sqlServerAadAdminObjectId
    sqlServerAdAdminLogin: sqlServerAdAdminLogin
    sqlServerVersion: sqlServerVersion
    sqlServerMinimalTlsVersion: sqlServerMinimalTlsVersion
    aadAdminType: aadAdminType
    azureADOnlyAuthentication: azureADOnlyAuthentication
    sqlServerVirtualNetworkResourceGroupName: sqlServerVirtualNetworkResourceGroupName
    sqlServerVirtualNetworkName: sqlServerVirtualNetworkName
    sqlServerPrivateEndpointSubnetName: sqlServerPrivateEndpointSubnetName
    databases: databases
    sqlServerLogAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.LogAnalyticsWorkspaceId
    tags: tags
  }
}

// Encryption Key
module encryptionKey '../../../../bicep-modules/Bicep/modules//Storage/createSqlEncryptionKey.bicep' = {
  name: 'sql-encryption-key'
  params: {
    sqlKeyvaultName: keyvaultName
    sqlEncryptionKeyExpiryBaseDate: sqlEncryptionKeyExpiryBaseDate
    sqlEncryptionKeyName: sqlEncryptionKeyName
    tenantId: tenantId
    existingSqlServerName: sqlServerName
  }
  dependsOn: [SqlServer]
}

// Sql Server Encryption
module sqlServerEncryption '../../../../bicep-modules/Bicep/modules/Storage/sqlServerAddEncryption.bicep' = {
  name: 'sql-encryption'
  params: {
    sqlKeyvaultName: keyvaultName
    sqlEncryptionKeyName: sqlEncryptionKeyName
    existingSqlServerName: sqlServerName
  }
  dependsOn: [encryptionKey]
}

// Data Factory Encryption
module dataFactoryServerEncryption '../../../../bicep-modules/Bicep/modules/data/createDataFactoryEncryptionKey.bicep' = {
  name: 'dataFactory-encryption'
  params: {
    dataFactoryKeyvaultName: keyvaultName
    dataFactoryEncryptionKeyName: dataFactoryEncryptionKeyName
    tenantId: tenantId
    dataFactoryUserManageIdentityObjectId: managedIdentities.outputs.objectIds[dataMigrationTargetUmiIndex]
    dataFactoryEncryptionKeyExpiryBaseDate: dataFactoryEncryptionKeyExpiryBaseDate
  }
  dependsOn: [KeyVault]
}

// Data Factory
module dataFactoryServer '../../../../bicep-modules/Bicep/modules/data/dataFactory.bicep' = {
  name: 'dataFactory'
  params: {
    dataFactoryUserAssignedManagedIdentity: managedIdentities.outputs.identityResourceIds[dataMigrationTargetUmiIndex]
    dataFactoryName: dataFactoryName
    dataFactoryEncryptionKeyName: dataFactoryEncryptionKeyName
    dataFactoryKeyVaultName: keyvaultName
    dataFactoryPublicNetworkAccess: dataFactoryPublicNetworkAccess
    dataFactoryVirtualNetworkResourceGroupName: dataFactoryVirtualNetworkResourceGroupName
    dataFactoryVirtualNetworkName: dataFactoryVirtualNetworkName
    dataFactoryPrivateEndpointSubnetName: dataFactoryPrivateEndpointSubnetName
    tags: tags
  }
  dependsOn: [dataFactoryServerEncryption]
}

// Virtual Machine - SHIR
module shirVirtualMachine '../../../../bicep-modules/Bicep/modules/Compute/VirtualMachine.bicep' = {
  name: 'shir-virtual-machine'
  params: {
    virtualMachineNicSubnetResourceId: virtualMachineNicSubnetResourceId
    virtualMachineNicName: virtualMachineNicName
    virtualMachineCount: virtualMachineCount
    virtualMachineName: virtualMachineName
    virtualMachineZone: virtualMachineZone
    virtualMachineSize: virtualMachineSize
    virtualMachineDiskEncryptionSetId: virtualMachineDiskEncryptionSetId
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineImageOS: virtualMachineImageOS
    virtualMachineImageOSVersion: virtualMachineImageOSVersion
    tags: tags
  }
}

// Virtual Machine - DataSync VMs
module dataSyncVirtualMachine '../../../../bicep-modules/Bicep/modules/Compute/VirtualMachine.bicep' = {
  name: 'datasync-virtual-machine'
  params: {
    virtualMachineNicSubnetResourceId: virtualMachineNicSubnetResourceId
    virtualMachineNicName: virtualMachineNicName
    virtualMachineCount: virtualMachineCount
    virtualMachineName: virtualMachineName
    virtualMachineZone: virtualMachineZone
    virtualMachineSize: virtualMachineSize
    virtualMachineDiskEncryptionSetId: virtualMachineDiskEncryptionSetId
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineImageOS: virtualMachineImageOS
    virtualMachineImageOSVersion: virtualMachineImageOSVersion
    tags: tags
  }
}

// SSH Key
module sshKey '../../../../bicep-modules/Bicep/modules/Security/sshKeys.bicep' = {
  name: 'ssh-key'
  params: {
    location: location
    sshKeyname: sshKeyName
    sshPublicKey: sshPublicKey
    tags: tags
  }
}

// Storage Container for SFTP
resource sftpContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccountName}/default/n'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [storageAccount]
}

// SFTP Local User
resource sfLocalUser 'Microsoft.Storage/storageAccounts/localUsers@2023-01-01' = {
  name: '${storageAccountName}/c'
  properties: {
    hasSshKey: true
    hasSshPassword: false
    homeDirectory: ''
    sshAuthorizedKeys: [
      {
        description: 'CDB CCA Integration Server SSH Key'
        key: sshPublicKey
      }
    ]
    permissionScopes: [
      {
        resourceName: ''
        service: 'blob'
        permissions: 'rwl'
      }
    ]
  }
  dependsOn: [storageAccount, sfContainer]
}
