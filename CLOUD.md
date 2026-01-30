# SimpleChat with Azure NetApp Files Integration

## Project Overview

This project integrates **Azure NetApp Files (ANF)** as the enterprise storage layer for the SimpleChat AI chatbot application. The goal is to demonstrate how Azure NetApp Files can power AI/ML workloads by providing high-performance, enterprise-grade storage with multiple access protocols.

### Value Proposition

Azure NetApp Files brings unique capabilities to AI chatbot scenarios:

1. **Multi-Protocol Access**: Same data accessible via NFS, SMB, and S3-compatible Object REST API
2. **Enterprise Performance**: Sub-millisecond latency for AI/ML workloads
3. **Unified Data Platform**: No data duplication - single source of truth
4. **Azure AI Integration**: Native integration with Azure AI Search, AI Foundry, and other Azure services
5. **Cost Optimization**: Cool access tier for inactive data
6. **Enterprise Compliance**: SAP certified, GDPR, HIPAA compliant

---

## Technical Feasibility Assessment

### Status: **TECHNICALLY FEASIBLE** ✅

The integration of Azure NetApp Files with SimpleChat is technically viable through multiple approaches. The recommended approach leverages the **Object REST API (S3-compatible)** which provides the most elegant integration path with minimal code changes.

### Azure NetApp Files Capabilities

| Protocol | Support | Use Case in SimpleChat |
|----------|---------|----------------------|
| **NFS** (NFSv3, NFSv4.1) | ✅ Full | File processing, direct file access |
| **SMB** (2.x, 3.0, 3.1.1) | ✅ Full | Windows client access, hybrid scenarios |
| **Object REST API** (S3-compatible) | ✅ Available | Replace Azure Blob Storage, AI service integration |
| **Dual-Protocol** | ✅ Full | Same data via NFS+SMB simultaneously |

### Current SimpleChat Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SimpleChat Application                    │
│              (Flask on Azure App Service)                    │
└───────┬──────────────────────┬──────────────────┬──────────┘
        │                      │                  │
        ▼                      ▼                  ▼
   ┌──────────────┐   ┌────────────────────┐  ┌─────────────┐
   │Azure Blob    │   │ Azure Cosmos DB    │  │ Azure AI    │
   │Storage       │   │ (Metadata)         │  │ Search      │
   │              │   │                    │  │ (Vectors)   │
   │ • user-docs  │   │ • documents        │  │             │
   │ • group-docs │   │ • conversations    │  │             │
   │ • public-docs│   │ • messages         │  │             │
   └──────────────┘   └────────────────────┘  └─────────────┘
```

### Target Architecture with Azure NetApp Files

```
┌─────────────────────────────────────────────────────────────┐
│                    SimpleChat Application                    │
│              (Flask on Azure App Service)                    │
└───────┬──────────────────────┬──────────────────┬──────────┘
        │                      │                  │
        │ S3 API (boto3)       │                  │
        ▼                      ▼                  ▼
   ┌──────────────┐   ┌────────────────────┐  ┌─────────────┐
   │Azure NetApp  │   │ Azure Cosmos DB    │  │ Azure AI    │
   │Files         │   │ (Metadata)         │  │ Search      │
   │              │   │                    │  │ (Vectors)   │
   │ Object REST  │◄──┤                    │  │             │
   │ API (S3)     │   │                    │  │  ┌───────┐  │
   │    +         │   │                    │  │  │Native │  │
   │ NFS/SMB      │───┼────────────────────┼──┼──┤ ANF   │  │
   │              │   │                    │  │  │ Integ │  │
   └──────────────┘   └────────────────────┘  └──┴───────┴──┘
        │
        ▼
   ┌──────────────┐
   │ Enterprise   │
   │ NFS/SMB      │
   │ Clients      │
   └──────────────┘
```

---

## Integration Approaches

### Approach A: Object REST API (S3-Compatible) - **RECOMMENDED**

Replace Azure Blob Storage with Azure NetApp Files Object REST API.

**Advantages:**
- Minimal code changes (S3-compatible SDK)
- Same data accessible via NFS, SMB, AND S3 API simultaneously
- Native Azure AI service integration
- No data duplication

**Implementation:**
- Create ANF NetApp Account, Capacity Pool, and Volume
- Enable Object REST API on the volume
- Configure buckets for user-documents, group-documents, public-documents
- Replace Azure Blob Storage SDK calls with boto3 (S3) SDK calls
- Add ANF-specific Semantic Kernel plugin

### Approach B: NFS Mount Integration

Mount ANF NFS volume directly to Azure App Service.

**Advantages:**
- Direct filesystem access
- POSIX-compliant operations
- Best for temp file processing

**Implementation:**
- Create ANF NFS volume
- Configure Azure App Service with Azure Files or custom NFS mount
- Modify temp file paths to use NFS mount

### Approach C: Hybrid Architecture

Combine both approaches for maximum flexibility.

**Advantages:**
- Best of both worlds
- API access via S3 + Direct file access via NFS/SMB
- Enterprise workflow integration

---

## Implementation Plan

### Phase 1: Infrastructure Setup (Week 1)

#### 1.1 Create Azure NetApp Files Bicep Module

```bicep
// modules/azureNetAppFiles.bicep
targetScope = 'resourceGroup'

param location string
param appName string
param environment string
param tags object
param vnetId string
param subnetId string
param serviceLevel string = 'Premium' // Standard, Premium, Ultra

// NetApp Account
resource netAppAccount 'Microsoft.NetApp/netAppAccounts@2025-01-01' = {
  name: '${appName}-${environment}-anf'
  location: location
  tags: tags
  properties: {}
}

// Capacity Pool
resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2025-01-01' = {
  parent: netAppAccount
  name: '${appName}-${environment}-pool'
  location: location
  tags: tags
  properties: {
    serviceLevel: serviceLevel
    size: 4398046511104 // 4 TiB minimum
    qosType: 'Auto'
  }
}

// Volume with Object REST API enabled
resource volume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = {
  parent: capacityPool
  name: '${appName}-${environment}-vol'
  location: location
  tags: tags
  properties: {
    creationToken: '${appName}-${environment}-vol'
    serviceLevel: serviceLevel
    subnetId: subnetId
    usageThreshold: 107374182400 // 100 GiB
    protocolTypes: ['NFSv4.1']
    exportPolicy: {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: false
          unixReadWrite: true
          cifs: false
          nfsv3: false
          nfsv41: true
          allowedClients: '0.0.0.0/0'
        }
      ]
    }
  }
}

output netAppAccountName string = netAppAccount.name
output capacityPoolName string = capacityPool.name
output volumeName string = volume.name
output volumeId string = volume.id
output mountTargets array = volume.properties.mountTargets
```

#### 1.2 Create ANF Dedicated Subnet

```bicep
// Add to modules/virtualNetwork.bicep
{
  name: 'ANFSubnet'
  addressPrefix: '10.0.3.0/24'
  delegations: [
    {
      name: 'NetAppDelegation'
      properties: {
        serviceName: 'Microsoft.NetApp/volumes'
      }
    }
  ]
}
```

#### 1.3 Update main.bicep

```bicep
// Add parameter
param deployAzureNetAppFiles bool = true

// Add module deployment
module azureNetAppFiles 'modules/azureNetAppFiles.bicep' = if (deployAzureNetAppFiles) {
  name: 'azureNetAppFiles'
  scope: rg
  params: {
    location: location
    appName: appName
    environment: environment
    tags: tags
    vnetId: virtualNetwork.outputs.vNetId
    subnetId: virtualNetwork.outputs.anfSubnetId
    serviceLevel: 'Premium'
  }
}
```

### Phase 2: Application Integration (Week 2)

#### 2.1 Create ANF Storage Plugin

Create a new Semantic Kernel plugin for Azure NetApp Files Object REST API:

```python
# semantic_kernel_plugins/anf_storage_plugin.py
import boto3
from botocore.config import Config
from semantic_kernel.functions import kernel_function

class ANFStoragePlugin:
    """Plugin for Azure NetApp Files Object REST API (S3-compatible)"""

    def __init__(self, manifest):
        self.endpoint = manifest.get('endpoint')  # ANF Object REST API endpoint
        self.access_key = manifest.get('auth', {}).get('access_key')
        self.secret_key = manifest.get('auth', {}).get('secret_key')

        # Configure S3 client for ANF
        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=Config(
                signature_version='s3v4',
                s3={'addressing_style': 'path'}
            ),
            region_name='us-east-1'  # Required for ANF
        )

    @kernel_function(description="List all buckets in ANF volume")
    def list_buckets(self):
        response = self.s3_client.list_buckets()
        return [b['Name'] for b in response['Buckets']]

    @kernel_function(description="List objects in a bucket")
    def list_objects(self, bucket_name: str, prefix: str = ''):
        response = self.s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=prefix
        )
        return [obj['Key'] for obj in response.get('Contents', [])]

    @kernel_function(description="Get object content")
    def get_object(self, bucket_name: str, key: str):
        response = self.s3_client.get_object(Bucket=bucket_name, Key=key)
        return response['Body'].read()

    @kernel_function(description="Upload object to bucket")
    def put_object(self, bucket_name: str, key: str, body: bytes, metadata: dict = None):
        self.s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=body,
            Metadata=metadata or {}
        )
```

#### 2.2 Create ANF Storage Service

```python
# services/anf_storage_service.py
import boto3
from botocore.config import Config
from azure.identity import DefaultAzureCredential
import os

class ANFStorageService:
    """Service for interacting with Azure NetApp Files Object REST API"""

    def __init__(self):
        self.endpoint = os.getenv('ANF_OBJECT_API_ENDPOINT')
        self.auth_type = os.getenv('ANF_AUTH_TYPE', 'key')

        if self.auth_type == 'managed_identity':
            # Use Azure AD authentication
            credential = DefaultAzureCredential()
            # Get STS token for S3 operations
            self._setup_with_managed_identity(credential)
        else:
            # Use access key authentication
            self.access_key = os.getenv('ANF_ACCESS_KEY')
            self.secret_key = os.getenv('ANF_SECRET_KEY')
            self._setup_with_keys()

    def _setup_with_keys(self):
        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=Config(
                signature_version='s3v4',
                s3={'addressing_style': 'path'}
            ),
            region_name='us-east-1'
        )

    def upload_file(self, local_path: str, bucket: str, key: str, metadata: dict = None):
        """Upload a file to ANF Object Storage"""
        with open(local_path, 'rb') as f:
            self.s3_client.put_object(
                Bucket=bucket,
                Key=key,
                Body=f,
                Metadata=metadata or {}
            )

    def download_file(self, bucket: str, key: str, local_path: str):
        """Download a file from ANF Object Storage"""
        response = self.s3_client.get_object(Bucket=bucket, Key=key)
        with open(local_path, 'wb') as f:
            f.write(response['Body'].read())

    def delete_file(self, bucket: str, key: str):
        """Delete a file from ANF Object Storage"""
        self.s3_client.delete_object(Bucket=bucket, Key=key)

    def list_files(self, bucket: str, prefix: str = ''):
        """List files in a bucket"""
        response = self.s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix
        )
        return response.get('Contents', [])

    def get_file_metadata(self, bucket: str, key: str):
        """Get file metadata"""
        response = self.s3_client.head_object(Bucket=bucket, Key=key)
        return response.get('Metadata', {})
```

#### 2.3 Modify Document Upload Function

Update `functions_documents.py` to support ANF storage:

```python
def upload_to_anf(temp_file_path, user_id, document_id, blob_filename,
                  update_callback, group_id=None, public_workspace_id=None):
    """Uploads the file to Azure NetApp Files Object Storage."""
    from services.anf_storage_service import ANFStorageService

    anf_service = ANFStorageService()

    is_group = group_id is not None
    is_public_workspace = public_workspace_id is not None

    # Determine bucket based on workspace type
    if is_public_workspace:
        bucket = 'public-documents'
        key = f"{public_workspace_id}/{blob_filename}"
    elif is_group:
        bucket = 'group-documents'
        key = f"{group_id}/{blob_filename}"
    else:
        bucket = 'user-documents'
        key = f"{user_id}/{blob_filename}"

    metadata = {
        "document_id": str(document_id),
        "group_id": str(group_id) if is_group else "",
        "user_id": str(user_id) if not is_group else ""
    }

    update_callback(status=f"Uploading {blob_filename} to Azure NetApp Files...")

    anf_service.upload_file(
        local_path=temp_file_path,
        bucket=bucket,
        key=key,
        metadata=metadata
    )

    print(f"Successfully uploaded {blob_filename} to ANF at {bucket}/{key}")
    return f"{bucket}/{key}"
```

### Phase 3: Configuration & Testing (Week 3)

#### 3.1 Environment Variables

Add to `.env` and App Service configuration:

```bash
# Azure NetApp Files Configuration
ANF_ENABLED=true
ANF_OBJECT_API_ENDPOINT=https://<account>.blob.netapp.azure.com
ANF_AUTH_TYPE=managed_identity  # or 'key'
ANF_ACCESS_KEY=<access-key>     # if using key auth
ANF_SECRET_KEY=<secret-key>     # if using key auth
ANF_SERVICE_LEVEL=Premium       # Standard, Premium, Ultra

# Bucket/Container names (same as current blob containers)
ANF_USER_DOCUMENTS_BUCKET=user-documents
ANF_GROUP_DOCUMENTS_BUCKET=group-documents
ANF_PUBLIC_DOCUMENTS_BUCKET=public-documents
```

#### 3.2 Admin Settings Integration

Add ANF configuration to admin settings UI:

```python
# In route_backend_control_center.py
anf_settings = {
    'anf_enabled': request.form.get('anf_enabled', 'false'),
    'anf_object_api_endpoint': request.form.get('anf_object_api_endpoint', ''),
    'anf_auth_type': request.form.get('anf_auth_type', 'key'),
    'anf_service_level': request.form.get('anf_service_level', 'Premium'),
}
```

### Phase 4: Azure AI Search Integration (Week 4)

#### 4.1 Configure Azure AI Search Indexer for ANF

Azure AI Search can index data directly from Azure NetApp Files Object REST API:

```json
{
  "name": "anf-indexer",
  "dataSourceName": "anf-datasource",
  "targetIndexName": "simplechat-documents",
  "parameters": {
    "configuration": {
      "dataToExtract": "contentAndMetadata",
      "parsingMode": "default"
    }
  }
}
```

#### 4.2 Create ANF Data Source

```json
{
  "name": "anf-datasource",
  "type": "azureblob",
  "credentials": {
    "connectionString": "DefaultEndpointsProtocol=https;AccountName=<anf-object-api>;..."
  },
  "container": {
    "name": "user-documents"
  }
}
```

---

## File Structure

```
simplechat-ANF/
├── application/
│   └── single_app/
│       ├── services/
│       │   └── anf_storage_service.py      # NEW: ANF storage service
│       ├── semantic_kernel_plugins/
│       │   ├── blob_storage_plugin.py      # Existing
│       │   └── anf_storage_plugin.py       # NEW: ANF plugin
│       ├── config.py                        # Updated: ANF config
│       ├── functions_documents.py           # Updated: ANF upload
│       └── route_backend_control_center.py  # Updated: ANF settings
├── deployers/
│   └── bicep/
│       ├── main.bicep                       # Updated: ANF deployment
│       └── modules/
│           ├── azureNetAppFiles.bicep       # NEW: ANF module
│           └── virtualNetwork.bicep         # Updated: ANF subnet
└── CLOUD.md                                 # This file
```

---

## Key Integration Points

| Component | Current (Blob Storage) | Target (Azure NetApp Files) |
|-----------|----------------------|---------------------------|
| File Upload | `upload_to_blob()` | `upload_to_anf()` |
| File Download | `BlobServiceClient` | `boto3.client('s3')` |
| Plugin | `blob_storage_plugin.py` | `anf_storage_plugin.py` |
| Infrastructure | `storageAccount.bicep` | `azureNetAppFiles.bicep` |
| AI Search Index | Blob indexer | ANF Object API indexer |

---

## Benefits of Azure NetApp Files for AI Chatbot

### 1. Performance
- **Sub-millisecond latency** for document retrieval
- **Premium/Ultra tiers** for high-throughput AI workloads
- **Optimized for RAG** (Retrieval Augmented Generation) patterns

### 2. Multi-Protocol Access
- **S3 API**: Application access (SimpleChat)
- **NFS**: Linux-based processing, data science notebooks
- **SMB**: Windows clients, enterprise file sharing
- **Same data, multiple access paths**

### 3. Enterprise Integration
- **No data movement**: Use existing enterprise data
- **Unified storage**: Single source of truth
- **Compliance ready**: SAP, GDPR, HIPAA certified

### 4. Cost Optimization
- **Cool access tier**: Automatic tiering for inactive data
- **Pay for what you use**: Flexible capacity pools
- **No egress charges**: Data stays in Azure

### 5. Azure AI Native Integration
- **Azure AI Search**: Direct indexing from ANF
- **Azure AI Foundry**: Native data connector
- **Azure Databricks**: Direct access for analytics

---

## Demo Scenarios

### Scenario 1: Enterprise Document Chat
1. User uploads documents via SimpleChat UI
2. Documents stored in Azure NetApp Files (Object REST API)
3. Azure AI Search indexes documents directly from ANF
4. Chat queries retrieve context from indexed documents
5. Same documents accessible via NFS for data science team

### Scenario 2: Multi-Modal Data Access
1. Data scientists prepare training data via NFS mount
2. Training data stored on Azure NetApp Files
3. Application accesses same data via S3 API
4. Business users access reports via SMB
5. **No data duplication** - single source of truth

### Scenario 3: High-Performance RAG
1. Large document corpus on Azure NetApp Files
2. Ultra tier provides sub-millisecond retrieval
3. Azure AI Search indexes chunks with embeddings
4. Chat application performs fast semantic search
5. Real-time responses with enterprise data

---

## References

- [Azure NetApp Files Documentation](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Azure NetApp Files Object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [Configure Object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure)
- [ANF + Azure AI Integration](https://techcommunity.microsoft.com/blog/azurearchitectureblog/how-azure-netapp-files-object-rest-api-powers-azure-and-isv-data-and-ai-services/4459545)
- [Azure NetApp Files Bicep Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.netapp/netappaccounts)
- [SimpleChat Original Repository](https://github.com/microsoft/simplechat)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-01-29 | Initial ANF integration plan |
