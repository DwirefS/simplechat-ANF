targetScope = 'subscription'

@minLength(1)
@description('''The Azure region where resources will be deployed.  
- Region must align to the target cloud environment''')
param location string

@description('''The target Azure Cloud environment.
- Accepted values are: AzureCloud, AzureUSGovernment
- Default is AzureCloud''')
@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
param cloudEnvironment string

@description('''The name of the application to be deployed.  
- Name may only contain letters and numbers
- Between 3 and 12 characters in length 
- No spaces or special characters''')
@minLength(3)
@maxLength(12)
param appName string

@description('''The dev/qa/prod environment or as named in your environment. This will be used to create resource group names and tags.
- Must be between 2 and 10 characters in length
- No spaces or special characters''')
@minLength(2)
@maxLength(10)
param environment string

@minLength(1)
@maxLength(64)
@description('Name of the AZD environment')
param azdEnvironmentName string

@description('''The name of the container image to deploy to the web app.
- should be in the format <repository>:<tag>''')
param imageName string

@description('''Azure AD Application Client ID for enterprise authentication.
- Should be the client ID of the registered Azure AD application''')
param enterpriseAppClientId string

@description('''Azure AD Application Service Principal Id for the enterprise application.
- Should be the Service Principal ID of the registered Azure AD application''')
param enterpriseAppServicePrincipalId string

@description('''Azure AD Application Client Secret for enterprise authentication.
- Required if enableEnterpriseApp is true
- Should be created in Azure AD App Registration and passed via environment variable
- Will be stored securely in Azure Key Vault during deployment''')
@secure()
param enterpriseAppClientSecret string

//----------------
// configurations
@description('''Authentication type for resources that support Managed Identity or Key authentication.
- Key: Use access keys for authentication (application keys will be stored in Key Vault)
- managed_identity: Use Managed Identity for authentication''')
@allowed([
  'key'
  'managed_identity'
])
param authenticationType string

@description('''Configure permissions (based on authenticationType) for the deployed web application to access required resources.
''')
param configureApplicationPermissions bool

@description('Optional object containing additional tags to apply to all resources.')
param specialTags object = {}

@description('''Enable diagnostic logging for resources deployed in the resource group. 
- All content will be sent to the deployed Log Analytics workspace
- Default is false''')
param enableDiagLogging bool

@description('''Enable private endpoints and virtual network integration for deployed resources. 
- Default is false''')
param enablePrivateNetworking bool

@description('''Array of GPT model names to deploy to the OpenAI resource.''')
param gptModels array = [
  {
    modelName: 'gpt-4.1'
    modelVersion: '2025-04-14'
    skuName: 'GlobalStandard'
    skuCapacity: 150
  }
  {
    modelName: 'gpt-4o'
    modelVersion: '2024-11-20'
    skuName: 'GlobalStandard'
    skuCapacity: 100
  }
]

@description('''Array of embedding model names to deploy to the OpenAI resource.''')
param embeddingModels array = [
  {
    modelName: 'text-embedding-3-small'
    modelVersion: '1'
    skuName: 'GlobalStandard'
    skuCapacity: 150
  }
  {
    modelName: 'text-embedding-3-large'
    modelVersion: '1'
    skuName: 'GlobalStandard'
    skuCapacity: 150
  }
]

//----------------
// allowed IP addresses for resources
@description('''Comma separated list of IP addresses or ranges to allow access to resources when private networking is enabled.
Leave blank if not using private networking.
- Format for single IP: 'x.x.x.x'
- Format for range: 'x.x.x.x/y'
- Example:  1.2.3.4, 2.3.4.5/32
''')
param allowedIpAddresses string
var allowedIpAddressesSplit = empty(allowedIpAddresses) ? [] : split(allowedIpAddresses!, ',')
var allowedIpAddressesArray = [for ip in allowedIpAddressesSplit: trim(ip)]
//----------------

// optional services

@description('''Enable deployment of Content Safety service and related resources.
- Default is false''')
param deployContentSafety bool

@description('''Enable deployment of Azure Cache for Redis and related resources.
- Default is false''')
param deployRedisCache bool

@description('''Enable deployment of Azure Speech service and related resources.
- Default is false''')
param deploySpeechService bool

@description('''Enable deployment of Azure Video Indexer service and related resources.
- Default is false''')
param deployVideoIndexerService bool

@description('''Enable deployment of Azure NetApp Files for enterprise storage.
- Provides NFS, SMB, and S3-compatible Object REST API access
- Requires private networking to be enabled
- Default is false''')
param deployAzureNetAppFiles bool = false

@description('''Azure NetApp Files service level.
- Standard: For static web content, file shares, database backups
- Premium: Sub-millisecond latency for enterprise apps, AI workloads
- Ultra: Most performance-intensive applications
- Default is Premium''')
@allowed([
  'Standard'
  'Premium'
  'Ultra'
])
param anfServiceLevel string = 'Premium'

@description('''Azure NetApp Files protocol type.
- NFSv4.1: Linux/Unix access (recommended for AI workloads)
- NFSv3: Legacy NFS support
- SMB: Windows access
- DualProtocol: Both NFS and SMB
- Default is NFSv4.1''')
@allowed([
  'NFSv3'
  'NFSv4.1'
  'SMB'
  'DualProtocol'
])
param anfProtocolType string = 'NFSv4.1'

//=========================================================
// variable declarations for the main deployment
//=========================================================
var rgName = '${appName}-${environment}-rg'
var requiredTags = { application: appName, environment: environment, 'azd-env-name': azdEnvironmentName }
var tags = union(requiredTags, specialTags)
var acrCloudSuffix = cloudEnvironment == 'AzureCloud' ? '.azurecr.io' : '.azurecr.us'
var acrName = toLower('${appName}${environment}acr')
var containerRegistry = '${acrName}${acrCloudSuffix}'
var containerImageName = '${containerRegistry}/${imageName}'
var vNetName = '${appName}-${environment}-vnet'
var allowedIpsForCosmos = union(['0.0.0.0'], allowedIpAddressesArray)
var cosmosDbIpRules = [for ip in allowedIpsForCosmos: {
  ipAddressOrRange: ip
}]
var acrIpRules = [for ip in allowedIpAddressesArray: {
  action: 'Allow'
  value: ip
}]

//=========================================================
// Resource group deployment
//=========================================================
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: tags
}

//=========================================================
// Create Virtual Network if private networking or ANF is enabled
// ANF requires a delegated subnet even without private endpoints
//=========================================================
module virtualNetwork 'modules/virtualNetwork.bicep' = if (enablePrivateNetworking || deployAzureNetAppFiles) {
  scope: rg
  name: 'virtualNetwork'
  params: {
    location: location
    vNetName: vNetName
    addressSpaces: ['10.0.0.0/21']
    subnetConfigs: concat([
      {
        name: 'AppServiceIntegration' // this subnet name must be present for app service vnet integration
        addressPrefix: '10.0.0.0/24'
        enablePrivateEndpointNetworkPolicies: true
        enablePrivateLinkServiceNetworkPolicies: true
      }
      {
        name: 'PrivateEndpoints' // this subnet name must be present if private endpoints are to be used
        addressPrefix: '10.0.2.0/24'
        enablePrivateEndpointNetworkPolicies: true
        enablePrivateLinkServiceNetworkPolicies: true
      }
    ], deployAzureNetAppFiles ? [
      {
        name: 'ANFSubnet' // this subnet is delegated to Microsoft.NetApp/volumes for Azure NetApp Files
        addressPrefix: '10.0.3.0/24'
        enablePrivateEndpointNetworkPolicies: true
        enablePrivateLinkServiceNetworkPolicies: true
      }
    ] : [])
    tags: tags
  }
}

//=========================================================
// Create log analytics workspace 
//=========================================================
module logAnalytics 'modules/logAnalyticsWorkspace.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
  }
}

//=========================================================
// Create application insights
//=========================================================
module applicationInsights 'modules/applicationInsights.bicep' = {
  name: 'applicationInsights'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId
  }
}

//=========================================================
// Create key vault
//=========================================================
module keyVault 'modules/keyVault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId
  }
}

//=========================================================
// Store enterprise app client secret in key vault
//=========================================================
module storeEnterpriseAppSecret 'modules/keyVault-Secrets.bicep' = if (!empty(enterpriseAppClientSecret)) {
  name: 'storeEnterpriseAppSecret'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'enterprise-app-client-secret'
    secretValue: enterpriseAppClientSecret
  }
}

//=========================================================
// Create CosmosDB resource
//=========================================================
module cosmosDB 'modules/cosmosDb.bicep' = {
  name: 'cosmosDB'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions
    enablePrivateNetworking: enablePrivateNetworking
    allowedIpAddresses: cosmosDbIpRules
  }
}

//=========================================================
// Create Azure Container Registry
//=========================================================
module acr 'modules/azureContainerRegistry.bicep' = {
  name: 'azureContainerRegistry'
  scope: rg
  params: {
    location: location
    acrName: acrName
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions
    enablePrivateNetworking: enablePrivateNetworking
    allowedIpAddresses: acrIpRules
  }
}

//=========================================================
// Create Search Service resource
//=========================================================
module searchService 'modules/search.bicep' = {
  name: 'searchService'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create Document Intelligence resource
//=========================================================
module docIntel 'modules/documentIntelligence.bicep' = {
  name: 'docIntel'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create storage account
//=========================================================
module storageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create - OpenAI Service
//=========================================================
module openAI 'modules/openAI.bicep' = {
  name: 'openAI'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    gptModels: gptModels
    embeddingModels: embeddingModels

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create App Service Plan
//=========================================================
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId
  }
}

//=========================================================
// Create App Service (Web App for Containers)
//=========================================================
module appService 'modules/appService.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    acrName: acr.outputs.acrName
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    containerImageName: containerImageName
    azurePlatform: cloudEnvironment
    cosmosDbName: cosmosDB.outputs.cosmosDbName
    searchServiceName: searchService.outputs.searchServiceName
    openAiServiceName: openAI.outputs.openAIName
    openAiResourceGroupName: openAI.outputs.openAIResourceGroup
    documentIntelligenceServiceName: docIntel.outputs.documentIntelligenceServiceName
    appInsightsName: applicationInsights.outputs.appInsightsName
    enterpriseAppClientId: enterpriseAppClientId
    enterpriseAppClientSecret: enterpriseAppClientSecret
    authenticationType: authenticationType
    keyVaultUri: keyVault.outputs.keyVaultUri

    enablePrivateNetworking: enablePrivateNetworking
    #disable-next-line BCP318 // expect one value to be null if private networking is disabled
    appServiceSubnetId: enablePrivateNetworking? virtualNetwork.outputs.appServiceSubnetId : ''
  }
}

//=========================================================
// configure optional services
//=========================================================

//=========================================================
// Create Optional Resource - Content Safety
//=========================================================
module contentSafety 'modules/contentSafety.bicep' = if (deployContentSafety) {
  name: 'contentSafety'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create Optional Resource - Redis Cache
//=========================================================
module redisCache 'modules/redisCache.bicep' = if (deployRedisCache) {
  name: 'redisCache'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    //enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create Optional Resource - Speech Service
//=========================================================
module speechService 'modules/speechService.bicep' = if (deploySpeechService) {
  name: 'speechService'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create Optional Resource - Video Indexer Service
//=========================================================
module videoIndexerService 'modules/videoIndexer.bicep' = if (deployVideoIndexerService) {
  name: 'videoIndexerService'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    storageAccount: storageAccount.outputs.name
    openAiServiceName: openAI.outputs.openAIName

    enablePrivateNetworking: enablePrivateNetworking
  }
}

//=========================================================
// Create Optional Resource - Azure NetApp Files
// Provides enterprise storage with NFS, SMB, and S3-compatible Object REST API
//=========================================================
module azureNetAppFiles 'modules/azureNetAppFiles.bicep' = if (deployAzureNetAppFiles) {
  name: 'azureNetAppFiles'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    enableDiagLogging: enableDiagLogging
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId

    keyVault: keyVault.outputs.keyVaultName
    authenticationType: authenticationType
    configureApplicationPermissions: configureApplicationPermissions

    // Network configuration - ANF requires a delegated subnet
    #disable-next-line BCP318 // value can't be null based on deployAzureNetAppFiles condition
    vNetId: virtualNetwork.outputs.vNetId
    #disable-next-line BCP318 // value can't be null based on deployAzureNetAppFiles condition
    anfSubnetId: virtualNetwork.outputs.anfSubnetId

    // ANF configuration
    serviceLevel: anfServiceLevel
    protocolType: anfProtocolType
    enableCoolAccess: false
    enableObjectApi: true
  }
}

//=========================================================
// configure permissions for managed identity to access resources
//=========================================================
module setPermissions 'modules/setPermissions.bicep' = if (configureApplicationPermissions) {
  name: 'setPermissions'
  scope: rg
  params: {

    webAppName: appService.outputs.name
    authenticationType: authenticationType
    enterpriseAppServicePrincipalId: enterpriseAppServicePrincipalId
    keyVaultName: keyVault.outputs.keyVaultName
    cosmosDBName: cosmosDB.outputs.cosmosDbName
    acrName: acr.outputs.acrName
    openAIName: openAI.outputs.openAIName
    docIntelName: docIntel.outputs.documentIntelligenceServiceName
    storageAccountName: storageAccount.outputs.name
    searchServiceName: searchService.outputs.searchServiceName

    #disable-next-line BCP318 // expect one value to be null
    speechServiceName: deploySpeechService ? speechService.outputs.speechServiceName : ''
    #disable-next-line BCP318 // expect one value to be null
    redisCacheName: deployRedisCache ? redisCache.outputs.redisCacheName : ''
    #disable-next-line BCP318 // expect one value to be null
    contentSafetyName: deployContentSafety ? contentSafety.outputs.contentSafetyName : ''
    #disable-next-line BCP318 // expect one value to be null
    videoIndexerName: deployVideoIndexerService ? videoIndexerService.outputs.videoIndexerServiceName : ''
  }
}

//=========================================================
// configure private networking
//=========================================================
module privateNetworking 'modules/privateNetworking.bicep' = if (enablePrivateNetworking) {
  name: 'privateNetworking'
  scope: rg
  params: {

    #disable-next-line BCP318 // value can't be null based on enablePrivateNetworking condition
    virtualNetworkId: virtualNetwork.outputs.vNetId
    #disable-next-line BCP318 // value can't be null based on enablePrivateNetworking condition
    privateEndpointSubnetId: virtualNetwork.outputs.privateNetworkSubnetId

    location: location
    appName: appName
    environment: environment
    tags: tags

    keyVaultName: keyVault.outputs.keyVaultName
    cosmosDBName: cosmosDB.outputs.cosmosDbName
    acrName: acr.outputs.acrName
    searchServiceName: searchService.outputs.searchServiceName
    docIntelName: docIntel.outputs.documentIntelligenceServiceName
    storageAccountName: storageAccount.outputs.name
    openAIName: openAI.outputs.openAIName
    webAppName: appService.outputs.name
    
    #disable-next-line BCP318 // expect one value to be null
    contentSafetyName: deployContentSafety ? contentSafety.outputs.contentSafetyName : ''
    #disable-next-line BCP318 // expect one value to be null
    speechServiceName: deploySpeechService ? speechService.outputs.speechServiceName : ''
    #disable-next-line BCP318 // expect one value to be null
    videoIndexerName: deployVideoIndexerService ? videoIndexerService.outputs.videoIndexerServiceName : ''
  }
}


//=========================================================
// output values
//=========================================================


// output values required for postprovision script in azure.yaml
output var_acrName string = toLower('${appName}${environment}acr')
output var_authenticationType string = toLower(authenticationType)
output var_blobStorageEndpoint string = storageAccount.outputs.endpoint
output var_configureApplication bool = configureApplicationPermissions
#disable-next-line BCP318 // expect one value to be null
output var_contentSafetyEndpoint string = deployContentSafety ? contentSafety.outputs.contentSafetyEndpoint : ''
output var_cosmosDb_accountName string = cosmosDB.outputs.cosmosDbName
output var_cosmosDb_uri string = cosmosDB.outputs.cosmosDbUri
output var_deploymentLocation string = rg.location
output var_documentIntelligenceServiceEndpoint string = docIntel.outputs.documentIntelligenceServiceEndpoint
output var_keyVaultName string = keyVault.outputs.keyVaultName
output var_keyVaultUri string = keyVault.outputs.keyVaultUri
output var_openAIEndpoint string = openAI.outputs.openAIEndpoint
output var_openAIGPTModels array = gptModels
output var_openAIResourceGroup string = openAI.outputs.openAIResourceGroup //may be able to remove
output var_openAIEmbeddingModels array = embeddingModels
#disable-next-line BCP318 // expect one value to be null
output var_redisCacheHostName string = deployRedisCache ? redisCache.outputs.redisCacheHostName : ''
output var_rgName string = rgName
output var_searchServiceEndpoint string = searchService.outputs.searchServiceEndpoint
#disable-next-line BCP318 // expect one value to be null
output var_speechServiceEndpoint string = deploySpeechService ? speechService.outputs.speechServiceEndpoint : ''
output var_subscriptionId string = subscription().subscriptionId
#disable-next-line BCP318 // expect one value to be null
output var_videoIndexerAccountId string = deployVideoIndexerService ? videoIndexerService.outputs.videoIndexerAccountId : ''
#disable-next-line BCP318 // expect one value to be null
output var_videoIndexerName string = deployVideoIndexerService ? videoIndexerService.outputs.videoIndexerServiceName : ''

// output values required for predeploy script in azure.yaml
output var_containerRegistry string = containerRegistry
output var_imageName string = contains(imageName, ':') ? split(imageName, ':')[0] : imageName
output var_imageTag string = split(imageName, ':')[1]
output var_webService string = appService.outputs.name

// output values required for postup script in azure.yaml
output var_enablePrivateNetworking bool = enablePrivateNetworking

// Azure NetApp Files outputs
output var_deployAzureNetAppFiles bool = deployAzureNetAppFiles
#disable-next-line BCP318 // expect one value to be null
output var_anfAccountName string = deployAzureNetAppFiles ? azureNetAppFiles.outputs.netAppAccountName : ''
#disable-next-line BCP318 // expect one value to be null
output var_anfCapacityPoolName string = deployAzureNetAppFiles ? azureNetAppFiles.outputs.capacityPoolName : ''
#disable-next-line BCP318 // expect one value to be null
output var_anfUserDocsVolumeName string = deployAzureNetAppFiles ? azureNetAppFiles.outputs.userDocsVolumeName : ''
#disable-next-line BCP318 // expect one value to be null
output var_anfGroupDocsVolumeName string = deployAzureNetAppFiles ? azureNetAppFiles.outputs.groupDocsVolumeName : ''
#disable-next-line BCP318 // expect one value to be null
output var_anfPublicDocsVolumeName string = deployAzureNetAppFiles ? azureNetAppFiles.outputs.publicDocsVolumeName : ''
output var_anfServiceLevel string = anfServiceLevel
output var_anfProtocolType string = anfProtocolType
