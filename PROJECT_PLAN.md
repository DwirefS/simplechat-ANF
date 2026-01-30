# SimpleChat-ANF Project Plan

## Executive Summary

This project adds **Azure NetApp Files** as the enterprise storage layer to the existing **Microsoft SimpleChat** AI chatbot demo. The goal is to demonstrate ANF's value proposition for AI workloads while preserving all existing SimpleChat functionality.

**Key Principle: ADD, DON'T DELETE** - All existing SimpleChat code, infrastructure, and functionality remains intact.

---

## Project Architecture

### Full SimpleChat + Azure NetApp Files Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SimpleChat-Azure NetApp Files                                     │
│                    (AI Chatbot with Azure NetApp Files)                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Azure App Service                                    │
│                    (Flask Application - single_app)                          │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  • app.py (Entry point)                                               │   │
│  │  • config.py (Azure client configuration)                             │   │
│  │  • functions_documents.py (Document processing)                       │   │
│  │  • functions_search.py (AI Search integration)                        │   │
│  │  • route_backend_*.py (API endpoints)                                 │   │
│  │  • semantic_kernel_plugins/ (AI plugins)                              │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└───────┬──────────────┬──────────────┬──────────────┬──────────────┬─────────┘
        │              │              │              │              │
        ▼              ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Azure OpenAI │ │ Azure AI     │ │ Azure        │ │ Storage      │ │ Azure        │
│              │ │ Search       │ │ Cosmos DB    │ │ Layer        │ │ Key Vault    │
│ • GPT Models │ │ • Vector     │ │ • Metadata   │ │              │ │ • Secrets    │
│ • Embeddings │ │   Index      │ │ • Convos     │ │ ┌──────────┐ │ │ • Keys       │
│              │ │ • Semantic   │ │ • Messages   │ │ │Blob      │ │ │              │
│              │ │   Search     │ │ • Documents  │ │ │Storage   │ │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ │ │(existing)│ │ └──────────────┘
                                                   │ └──────────┘ │
                                                   │      OR      │
                                                   │ ┌──────────┐ │
                                                   │ │Azure     │ │
                                                   │ │NetApp    │ │
                                                   │ │Files     │ │
                                                   │ │(NEW)     │ │
                                                   │ │• S3 API  │ │
                                                   │ │• NFS     │ │
                                                   │ │• SMB     │ │
                                                   │ └──────────┘ │
                                                   └──────────────┘
        │              │              │              │              │
        ▼              ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Azure Doc    │ │ Azure        │ │ Azure        │ │ Azure        │ │ Azure        │
│ Intelligence │ │ Content      │ │ Speech       │ │ Video        │ │ Redis        │
│              │ │ Safety       │ │ Service      │ │ Indexer      │ │ Cache        │
│ • PDF        │ │ (Optional)   │ │ (Optional)   │ │ (Optional)   │ │ (Optional)   │
│ • Office     │ │              │ │ • Audio      │ │ • Video      │ │ • Sessions   │
│ • Images     │ │              │ │   Transcribe │ │   Process    │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## All SimpleChat Components (KEEP ALL)

### Core Services (Required)

| Service | Bicep Module | Purpose | Status |
|---------|--------------|---------|--------|
| Azure App Service | `appService.bicep` | Host Flask application | KEEP |
| Azure Container Registry | `containerRegistry.bicep` | Docker images | KEEP |
| Azure Cosmos DB | `cosmosDb.bicep` | Metadata, conversations | KEEP |
| Azure Blob Storage | `storageAccount.bicep` | Document storage (existing) | KEEP |
| **Azure NetApp Files** | `azureNetAppFiles.bicep` | Document storage (new) | **ADD** |
| Azure AI Search | `search.bicep` | Vector/semantic search | KEEP |
| Azure OpenAI | `openAI.bicep` | LLM capabilities | KEEP |
| Azure Document Intelligence | `documentIntelligence.bicep` | Document extraction | KEEP |
| Azure Key Vault | `keyVault.bicep` | Secrets management | KEEP |
| Log Analytics | `logAnalyticsWorkspace.bicep` | Monitoring | KEEP |
| Application Insights | `applicationInsights.bicep` | Telemetry | KEEP |

### Optional Services

| Service | Bicep Module | Purpose | Status |
|---------|--------------|---------|--------|
| Azure Cache for Redis | `redisCache.bicep` | Session caching | KEEP |
| Azure Content Safety | `contentSafety.bicep` | Content filtering | KEEP |
| Azure Speech Service | `speechService.bicep` | Audio transcription | KEEP |
| Azure Video Indexer | `videoIndexer.bicep` | Video processing | KEEP |
| Private Networking | `privateNetworking.bicep` | VNet integration | KEEP |
| Virtual Network | `virtualNetwork.bicep` | Network infrastructure | KEEP (+ Azure NetApp Files subnet) |

---

## Infrastructure Files (All Required)

### Bicep Deployment (`deployers/bicep/`)

```
deployers/bicep/
├── main.bicep                          # Main orchestrator (UPDATED for Azure NetApp Files)
├── main.parameters.json                # Parameters (UPDATED for Azure NetApp Files)
└── modules/
    ├── appService.bicep                # KEEP
    ├── applicationInsights.bicep       # KEEP
    ├── azureNetAppFiles.bicep          # NEW - Azure NetApp Files module
    ├── containerRegistry.bicep         # KEEP
    ├── contentSafety.bicep             # KEEP
    ├── cosmosDb.bicep                  # KEEP
    ├── diagnosticSettings.bicep        # KEEP
    ├── documentIntelligence.bicep      # KEEP
    ├── keyVault.bicep                  # KEEP
    ├── logAnalyticsWorkspace.bicep     # KEEP
    ├── openAI.bicep                    # KEEP
    ├── privateNetworking.bicep         # KEEP
    ├── redisCache.bicep                # KEEP
    ├── search.bicep                    # KEEP
    ├── setPermissions.bicep            # KEEP
    ├── speechService.bicep             # KEEP
    ├── storageAccount.bicep            # KEEP (existing blob storage)
    ├── videoIndexer.bicep              # KEEP
    └── virtualNetwork.bicep            # UPDATED (added Azure NetApp Files subnet)
```

### Terraform Deployment (`deployers/terraform/`)

```
deployers/terraform/
├── main.tf                             # KEEP + ADD Azure NetApp Files module
├── variables.tf                        # KEEP + ADD Azure NetApp Files variables
├── outputs.tf                          # KEEP + ADD Azure Netapp Files outputs
└── modules/
    └── azure_netapp_files/             # NEW - Azure NetApp Files module (to create)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Application Code (All Required)

### Flask Application (`application/single_app/`)

```
application/single_app/
├── app.py                              # KEEP - Flask entry point
├── config.py                           # KEEP + ADD Azure NetApp Files configuration
├── functions_documents.py              # KEEP + ADD Azure NetApp Files upload function
├── functions_*.py                      # KEEP - All function files
├── route_backend_*.py                  # KEEP - All route files
├── services/                           # NEW - Add services folder
│   └── anf_storage_service.py          # NEW - Azure NetApp Files storage service
├── semantic_kernel_plugins/
│   ├── blob_storage_plugin.py          # KEEP - Existing blob plugin
│   ├── anf_storage_plugin.py           # NEW - Azure NetApp Files plugin
│   └── [other plugins...]              # KEEP - All other plugins
├── templates/                          # KEEP - All templates
├── static/                             # KEEP - All static files
├── requirements.txt                    # KEEP + ADD boto3
├── Dockerfile                          # KEEP
└── example.env                         # KEEP + ADD Azure NetApp Files variables
```

### External Applications (`application/external_apps/`)

```
application/external_apps/
├── bulkloader/                         # KEEP - Bulk document upload
│   ├── main.py
│   └── example.env
└── databaseseeder/                     # KEEP - Database seeding
    ├── main.py
    └── example.env
```

---

## Implementation Phases

### Phase 1: Infrastructure (Completed)

| Task | Status | Files |
|------|--------|-------|
| Create Azure NetApp Files Bicep module | ✅ Done | `modules/azureNetAppFiles.bicep` |
| Update VNet for Azure NetApp Files subnet | ✅ Done | `modules/virtualNetwork.bicep` |
| Update main.bicep for Azure NetApp Files | ✅ Done | `main.bicep` |
| Add Azure NetApp Files deployment parameters | ✅ Done | `main.bicep` |
| Add Azure NetApp Files outputs | ✅ Done | `main.bicep` |

### Phase 2: Application Code (Next)

| Task | Status | Files |
|------|--------|-------|
| Create Azure NetApp Files storage service | 🔲 Pending | `services/anf_storage_service.py` |
| Create Azure NetApp Files storage plugin | 🔲 Pending | `semantic_kernel_plugins/anf_storage_plugin.py` |
| Add storage abstraction/toggle | 🔲 Pending | `config.py`, `functions_documents.py` |
| Add boto3 dependency | 🔲 Pending | `requirements.txt` |
| Update example.env | 🔲 Pending | `example.env` |

### Phase 3: Configuration & Admin (Future)

| Task | Status | Files |
|------|--------|-------|
| Add Azure NetApp Files settings to admin UI | 🔲 Pending | `route_backend_control_center.py` |
| Add Azure NetApp Files connection test | 🔲 Pending | `functions_admin.py` |
| Update settings templates | 🔲 Pending | `templates/admin/` |

### Phase 4: Azure AI Search Integration (Future)

| Task | Status | Files |
|------|--------|-------|
| Configure Azure NetApp Files data source | 🔲 Pending | Search configuration |
| Update indexer for Azure NetApp Files | 🔲 Pending | `functions_search.py` |
| Test vector search with Azure NetApp Files | 🔲 Pending | Testing |

### Phase 5: Terraform & Testing (Future)

| Task | Status | Files |
|------|--------|-------|
| Create Azure NetApp Files Terraform module | 🔲 Pending | `terraform/modules/azure_netapp_files/` |
| Update main.tf | 🔲 Pending | `terraform/main.tf` |
| End-to-end testing | 🔲 Pending | Testing |
| Documentation updates | 🔲 Pending | `README.md`, docs/ |

---

## Storage Configuration Toggle

The application will support both Blob Storage and Azure NetApp Files via configuration:

```python
# config.py
STORAGE_BACKEND = os.getenv('STORAGE_BACKEND', 'blob')  # 'blob' or 'anf'

# When STORAGE_BACKEND='blob' - use existing Azure Blob Storage
# When STORAGE_BACKEND='anf' - use Azure NetApp Files object REST API
```

This ensures:
1. **Backwards compatibility** - Default is existing Blob Storage
2. **Easy switching** - Change one environment variable
3. **Demo flexibility** - Show both options to customers

---

## ANF-Specific Configuration

```bash
# Azure NetApp Files Settings (add to example.env)
STORAGE_BACKEND=anf                                    # Toggle: 'blob' or 'anf'
ANF_OBJECT_API_ENDPOINT=https://<account>.blob.netapp.azure.com
ANF_AUTH_TYPE=managed_identity                         # or 'key'
ANF_ACCESS_KEY=<access-key>                            # if using key auth
ANF_SECRET_KEY=<secret-key>                            # if using key auth
ANF_SERVICE_LEVEL=Premium                              # Standard, Premium, Ultra
ANF_USER_DOCUMENTS_BUCKET=user-documents
ANF_GROUP_DOCUMENTS_BUCKET=group-documents
ANF_PUBLIC_DOCUMENTS_BUCKET=public-documents
```

---

## Demo Value Proposition

### For Customers

1. **Multi-Protocol Access**
   - Application uses S3 API for document storage
   - Data scientists access same data via NFS mount
   - Business users access via SMB shares
   - **No data duplication - single source of truth**

2. **Enterprise Performance**
   - Sub-millisecond latency for RAG retrieval
   - Premium/Ultra tiers for AI workloads
   - 4,500 MB/s throughput (Ultra tier)

3. **Azure AI Native Integration**
   - Azure AI Search indexes directly from Azure NetApp Files
   - Azure AI Foundry native connector
   - Seamless enterprise data integration

4. **Cost Optimization**
   - Cool access tier for inactive data
   - Standard tier for cost-sensitive workloads
   - No egress charges within Azure

---

## Success Criteria

| Criteria | Measurement |
|----------|-------------|
| All SimpleChat features work | 100% existing functionality preserved |
| Azure NetApp Files storage integration | Documents upload/download via S3 API |
| Multi-protocol demo | Same data accessible via NFS, SMB, S3 |
| One-click deployment | Bicep deploys all resources including Azure NetApp Files |
| Customer demo ready | Clear value proposition presentation |

---

## Next Steps

1. **Create Azure NetApp Files storage service** (`services/anf_storage_service.py`)
2. **Create Azure NetApp Files storage plugin** (`semantic_kernel_plugins/anf_storage_plugin.py`)
3. **Add storage toggle** in `config.py` and `functions_documents.py`
4. **Test document upload** with Azure NetApp Files object REST API
5. **Update documentation** for deployment with Azure NetApp Files

---

## References

- [SimpleChat Original](https://github.com/microsoft/simplechat)
- [Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Azure NetApp Files object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [Azure NetApp Files Bicep Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.netapp/netappaccounts)
