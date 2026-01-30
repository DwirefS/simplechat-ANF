targetScope = 'resourceGroup'

@description('Azure region for the NetApp resources')
param location string

@description('Application name prefix for resource naming')
param appName string

@description('Environment name (dev, qa, prod)')
param environment string

@description('Tags to apply to all resources')
param tags object

@description('Enable diagnostic logging')
param enableDiagLogging bool

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsId string

@description('Virtual Network ID for ANF subnet delegation')
param vNetId string

@description('Subnet ID delegated to Microsoft.NetApp/volumes')
param anfSubnetId string

@description('Key Vault name for storing credentials')
param keyVault string

@description('Authentication type: key or managed_identity')
@allowed([
  'key'
  'managed_identity'
])
param authenticationType string

@description('Configure application permissions')
param configureApplicationPermissions bool

@description('Service level for the capacity pool')
@allowed([
  'Standard'
  'Premium'
  'Ultra'
  'Flexible'
])
param serviceLevel string = 'Premium'

@description('Capacity pool size in bytes (minimum 4 TiB)')
param capacityPoolSizeBytes int = 4398046511104 // 4 TiB

@description('Volume quota size in bytes (minimum 100 GiB)')
param volumeQuotaSizeBytes int = 107374182400 // 100 GiB

@description('Enable cool access for cost optimization')
param enableCoolAccess bool = false

@description('Protocol type for the volume')
@allowed([
  'NFSv3'
  'NFSv4.1'
  'SMB'
  'DualProtocol'
])
param protocolType string = 'NFSv4.1'

@description('Enable Object REST API (S3-compatible)')
param enableObjectApi bool = true

// Import diagnostic settings configurations
module diagnosticConfigs 'diagnosticSettings.bicep' = if (enableDiagLogging) {
  name: 'anfDiagnosticConfigs'
}

//=========================================================
// Azure NetApp Files Account
//=========================================================
resource netAppAccount 'Microsoft.NetApp/netAppAccounts@2025-01-01' = {
  name: toLower('${appName}-${environment}-anf')
  location: location
  tags: tags
  properties: {
    // Active Directory configuration for SMB (optional)
    // activeDirectories: []
  }
}

//=========================================================
// Capacity Pool
//=========================================================
resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2025-01-01' = {
  parent: netAppAccount
  name: toLower('${appName}-${environment}-pool')
  location: location
  tags: tags
  properties: {
    serviceLevel: serviceLevel
    size: capacityPoolSizeBytes
    qosType: 'Auto'
    coolAccess: enableCoolAccess
  }
}

//=========================================================
// Volume for SimpleChat Documents
//=========================================================
resource volume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = {
  parent: capacityPool
  name: toLower('${appName}-${environment}-docs')
  location: location
  tags: tags
  properties: {
    creationToken: toLower('${appName}-${environment}-docs')
    serviceLevel: serviceLevel
    subnetId: anfSubnetId
    usageThreshold: volumeQuotaSizeBytes
    protocolTypes: protocolType == 'DualProtocol' ? ['NFSv4.1', 'CIFS'] : [protocolType == 'SMB' ? 'CIFS' : protocolType]

    // Network features
    networkFeatures: 'Standard'

    // Export policy for NFS access
    exportPolicy: protocolType != 'SMB' ? {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: false
          unixReadWrite: true
          cifs: protocolType == 'DualProtocol'
          nfsv3: protocolType == 'NFSv3'
          nfsv41: protocolType == 'NFSv4.1' || protocolType == 'DualProtocol'
          allowedClients: '0.0.0.0/0'
          kerberos5ReadOnly: false
          kerberos5ReadWrite: false
          kerberos5iReadOnly: false
          kerberos5iReadWrite: false
          kerberos5pReadOnly: false
          kerberos5pReadWrite: false
        }
      ]
    } : null

    // Cool access settings
    coolAccess: enableCoolAccess
    coolAccessRetrievalPolicy: enableCoolAccess ? 'Default' : null

    // Security style
    securityStyle: protocolType == 'SMB' ? 'ntfs' : 'unix'
  }
}

//=========================================================
// Volume for User Documents Bucket
//=========================================================
resource volumeUserDocs 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = {
  parent: capacityPool
  name: toLower('${appName}-${environment}-user-docs')
  location: location
  tags: tags
  properties: {
    creationToken: 'user-documents'
    serviceLevel: serviceLevel
    subnetId: anfSubnetId
    usageThreshold: volumeQuotaSizeBytes
    protocolTypes: [protocolType == 'SMB' ? 'CIFS' : protocolType]
    networkFeatures: 'Standard'
    exportPolicy: protocolType != 'SMB' ? {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: false
          unixReadWrite: true
          cifs: false
          nfsv3: protocolType == 'NFSv3'
          nfsv41: protocolType == 'NFSv4.1'
          allowedClients: '0.0.0.0/0'
          kerberos5ReadOnly: false
          kerberos5ReadWrite: false
          kerberos5iReadOnly: false
          kerberos5iReadWrite: false
          kerberos5pReadOnly: false
          kerberos5pReadWrite: false
        }
      ]
    } : null
    securityStyle: protocolType == 'SMB' ? 'ntfs' : 'unix'
  }
  dependsOn: [volume] // Ensure sequential creation
}

//=========================================================
// Volume for Group Documents Bucket
//=========================================================
resource volumeGroupDocs 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = {
  parent: capacityPool
  name: toLower('${appName}-${environment}-group-docs')
  location: location
  tags: tags
  properties: {
    creationToken: 'group-documents'
    serviceLevel: serviceLevel
    subnetId: anfSubnetId
    usageThreshold: volumeQuotaSizeBytes
    protocolTypes: [protocolType == 'SMB' ? 'CIFS' : protocolType]
    networkFeatures: 'Standard'
    exportPolicy: protocolType != 'SMB' ? {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: false
          unixReadWrite: true
          cifs: false
          nfsv3: protocolType == 'NFSv3'
          nfsv41: protocolType == 'NFSv4.1'
          allowedClients: '0.0.0.0/0'
          kerberos5ReadOnly: false
          kerberos5ReadWrite: false
          kerberos5iReadOnly: false
          kerberos5iReadWrite: false
          kerberos5pReadOnly: false
          kerberos5pReadWrite: false
        }
      ]
    } : null
    securityStyle: protocolType == 'SMB' ? 'ntfs' : 'unix'
  }
  dependsOn: [volumeUserDocs] // Ensure sequential creation
}

//=========================================================
// Volume for Public Documents Bucket
//=========================================================
resource volumePublicDocs 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = {
  parent: capacityPool
  name: toLower('${appName}-${environment}-public-docs')
  location: location
  tags: tags
  properties: {
    creationToken: 'public-documents'
    serviceLevel: serviceLevel
    subnetId: anfSubnetId
    usageThreshold: volumeQuotaSizeBytes
    protocolTypes: [protocolType == 'SMB' ? 'CIFS' : protocolType]
    networkFeatures: 'Standard'
    exportPolicy: protocolType != 'SMB' ? {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: false
          unixReadWrite: true
          cifs: false
          nfsv3: protocolType == 'NFSv3'
          nfsv41: protocolType == 'NFSv4.1'
          allowedClients: '0.0.0.0/0'
          kerberos5ReadOnly: false
          kerberos5ReadWrite: false
          kerberos5iReadOnly: false
          kerberos5iReadWrite: false
          kerberos5pReadOnly: false
          kerberos5pReadWrite: false
        }
      ]
    } : null
    securityStyle: protocolType == 'SMB' ? 'ntfs' : 'unix'
  }
  dependsOn: [volumeGroupDocs] // Ensure sequential creation
}

//=========================================================
// Outputs
//=========================================================
output netAppAccountName string = netAppAccount.name
output netAppAccountId string = netAppAccount.id
output capacityPoolName string = capacityPool.name
output capacityPoolId string = capacityPool.id

// Main volume outputs
output volumeName string = volume.name
output volumeId string = volume.id
output volumeMountTargets array = volume.properties.mountTargets

// User documents volume
output userDocsVolumeName string = volumeUserDocs.name
output userDocsVolumeId string = volumeUserDocs.id
output userDocsMountTargets array = volumeUserDocs.properties.mountTargets

// Group documents volume
output groupDocsVolumeName string = volumeGroupDocs.name
output groupDocsVolumeId string = volumeGroupDocs.id
output groupDocsMountTargets array = volumeGroupDocs.properties.mountTargets

// Public documents volume
output publicDocsVolumeName string = volumePublicDocs.name
output publicDocsVolumeId string = volumePublicDocs.id
output publicDocsMountTargets array = volumePublicDocs.properties.mountTargets

// Object REST API endpoint (when enabled via portal/CLI post-deployment)
// Note: Object REST API must be enabled via Azure Portal or CLI after volume creation
output objectApiEndpointNote string = 'Enable Object REST API via Azure Portal or CLI: az netappfiles volume update --enable-subvolumes Enabled'
