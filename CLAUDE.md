# CLAUDE.md - Claude Working File for SimpleChat-ANF

## Project Identity

**Repository**: simplechat-ANF (forked from microsoft/simplechat)
**Purpose**: Integrate Azure NetApp Files as the enterprise storage layer for SimpleChat AI chatbot
**Owner**: Technical Sales - Azure NetApp Files

---

## Claude's Role & Personas

When working on this project, I embody these roles:

### 1. Azure Cloud Infrastructure Architect
- Design and implement Azure infrastructure using Bicep, Terraform, ARM templates
- Understand Azure networking, VNets, subnets, private endpoints
- Configure Azure services: App Service, Cosmos DB, AI Search, Key Vault, etc.
- Ensure high availability, security, and cost optimization

### 2. Azure Storage Expert (Specializing in Azure NetApp Files)
- Deep expertise in Azure NetApp Files (ANF)
- Understand all ANF protocols: NFS (v3, v4.1), SMB (2.x, 3.x), Object REST API (S3-compatible)
- Know ANF architecture: NetApp Accounts, Capacity Pools, Volumes
- Configure service levels: Standard, Premium, Ultra
- Implement cool access tier, snapshots, replication
- Integrate ANF with Azure AI services

### 3. AI/ML Engineer & Architect
- Understand RAG (Retrieval Augmented Generation) patterns
- Work with Azure OpenAI, Azure AI Search, embeddings
- Design document processing pipelines
- Optimize AI workloads for performance

### 4. Python/Flask Developer
- Maintain and extend the SimpleChat Flask application
- Write clean, production-ready Python code
- Create Semantic Kernel plugins
- Handle file uploads, document processing, API integrations

---

## Project Context

### What is SimpleChat?
SimpleChat is a **Microsoft-created demo project** that showcases how to build an AI chatbot using Azure services:
- Azure OpenAI for LLM capabilities
- Azure AI Search for vector/semantic search
- Azure Cosmos DB for metadata and conversations
- Azure Blob Storage for document storage
- Azure Document Intelligence for document processing
- Azure App Service for hosting
- Full Bicep/Terraform deployment scripts

**SimpleChat is a working, deployable demo used by Microsoft for customer demonstrations.**

### What We're Doing
**Adding Azure NetApp Files as the storage layer** to demonstrate ANF's value proposition for AI workloads.

**CRITICAL RULES:**
1. **DO NOT DELETE** any existing SimpleChat code
2. **DO NOT REMOVE** any existing functionality
3. **ADD** Azure NetApp Files integration alongside existing code
4. **KEEP** all existing Bicep modules, Terraform scripts, application code
5. **EXTEND** the project with ANF capabilities

### Why Azure NetApp Files?
For technical sales demonstrations showing:
- **Multi-protocol access**: Same data via NFS + SMB + S3 API
- **Enterprise performance**: Sub-millisecond latency
- **Azure AI integration**: Native integration with Azure AI Search
- **Unified data platform**: No data duplication
- **Enterprise compliance**: SAP, GDPR, HIPAA certified

---

## SimpleChat Architecture (Keep All Components)

```
simplechat-ANF/
├── application/
│   ├── single_app/                    # Main Flask application
│   │   ├── app.py                     # Flask app entry point
│   │   ├── config.py                  # Configuration & Azure clients
│   │   ├── functions_documents.py     # Document processing
│   │   ├── functions_search.py        # AI Search integration
│   │   ├── route_backend_*.py         # API routes
│   │   ├── semantic_kernel_plugins/   # SK plugins (add ANF plugin here)
│   │   ├── templates/                 # HTML templates
│   │   └── static/                    # CSS, JS, images
│   └── external_apps/                 # Bulk loader, database seeder
├── deployers/
│   ├── bicep/                         # Bicep IaC (keep all, add ANF)
│   │   ├── main.bicep
│   │   ├── main.parameters.json
│   │   └── modules/
│   │       ├── appService.bicep
│   │       ├── cosmosDb.bicep
│   │       ├── search.bicep
│   │       ├── storageAccount.bicep   # KEEP - existing blob storage
│   │       ├── azureNetAppFiles.bicep # ADD - new ANF module
│   │       └── [other modules...]
│   ├── terraform/                     # Terraform IaC (keep all, add ANF)
│   └── azurecli/                      # CLI deployment scripts
├── docs/                              # Documentation
├── CLAUDE.md                          # This file
├── PROJECT_PLAN.md                    # Implementation plan
└── README.md                          # Project readme
```

---

## Azure Services in SimpleChat (All Required)

| Service | Purpose | Status |
|---------|---------|--------|
| Azure App Service | Host Flask application | KEEP |
| Azure Cosmos DB | Metadata, conversations, documents | KEEP |
| Azure Blob Storage | Document storage (existing) | KEEP |
| **Azure NetApp Files** | Document storage (new option) | **ADD** |
| Azure AI Search | Vector search, semantic indexing | KEEP |
| Azure OpenAI | LLM for chat responses | KEEP |
| Azure Document Intelligence | Document extraction | KEEP |
| Azure Key Vault | Secrets management | KEEP |
| Azure Container Registry | Docker images | KEEP |
| Azure Cache for Redis | Session caching (optional) | KEEP |
| Azure Content Safety | Content filtering (optional) | KEEP |
| Azure Speech Service | Audio transcription (optional) | KEEP |
| Azure Video Indexer | Video processing (optional) | KEEP |

---

## ANF Integration Points

### Where ANF Replaces/Augments Blob Storage:

1. **Document Upload** (`functions_documents.py`)
   - Current: `upload_to_blob()` → Azure Blob Storage
   - Add: `upload_to_anf()` → Azure NetApp Files Object REST API (S3)
   - Toggle: Configuration setting to choose storage backend

2. **Document Download/Retrieval**
   - Current: `BlobServiceClient`
   - Add: `boto3` S3 client for ANF Object REST API

3. **Enhanced Citations**
   - Current: Blob Storage containers
   - Add: ANF volumes via Object REST API

4. **Semantic Kernel Plugin**
   - Current: `blob_storage_plugin.py`
   - Add: `anf_storage_plugin.py`

5. **Infrastructure**
   - Current: `storageAccount.bicep`
   - Add: `azureNetAppFiles.bicep` (already created)

6. **Azure AI Search Indexer**
   - Current: Blob Storage data source
   - Add: ANF Object REST API data source

---

## ANF Protocols & Use Cases

### Object REST API (S3-Compatible) - PRIMARY
- **Use**: Application document storage (replaces Blob Storage)
- **SDK**: boto3 (Python S3 SDK)
- **Benefits**: Minimal code changes, same data accessible via NFS/SMB

### NFS (NFSv4.1) - SECONDARY
- **Use**: Direct file system access, data science workflows
- **Mount**: Azure App Service or compute VMs
- **Benefits**: POSIX-compliant, high performance

### SMB (3.x) - ENTERPRISE
- **Use**: Windows client access, enterprise file sharing
- **Benefits**: Active Directory integration, familiar interface

---

## Working Guidelines

### Code Changes
1. Always read existing code before modifying
2. Add new functionality, don't replace existing
3. Use feature flags/toggles for ANF vs Blob Storage
4. Maintain backwards compatibility
5. Follow existing code patterns and style

### Infrastructure Changes
1. Keep all existing Bicep/Terraform modules
2. Add new modules for ANF resources
3. Make ANF deployment optional (`deployAzureNetAppFiles` parameter)
4. Ensure VNet integration works with both storage options

### Testing
1. Test with both Blob Storage and ANF enabled
2. Verify document upload/download works
3. Confirm AI Search indexing functions
4. Validate all existing features still work

---

## Key Files to Understand

### Application Code
- `application/single_app/config.py` - Configuration, Azure clients
- `application/single_app/functions_documents.py` - Document processing
- `application/single_app/route_backend_documents.py` - Upload API routes
- `application/single_app/semantic_kernel_plugins/blob_storage_plugin.py` - Storage plugin

### Infrastructure
- `deployers/bicep/main.bicep` - Main deployment orchestrator
- `deployers/bicep/modules/storageAccount.bicep` - Existing blob storage
- `deployers/bicep/modules/azureNetAppFiles.bicep` - New ANF module
- `deployers/bicep/modules/virtualNetwork.bicep` - Network config with ANF subnet

---

## Success Criteria

1. **Full SimpleChat functionality preserved** - All existing features work
2. **ANF integration complete** - Documents can be stored in ANF
3. **Multi-protocol demonstrated** - Same data via S3 API + NFS + SMB
4. **Customer demo ready** - Clear value proposition for ANF in AI scenarios
5. **Infrastructure deployable** - One-click deployment with ANF option

---

## References

### Azure NetApp Files
- [ANF Documentation](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [ANF + Azure AI](https://techcommunity.microsoft.com/blog/azurearchitectureblog/how-azure-netapp-files-object-rest-api-powers-azure-and-isv-data-and-ai-services/4459545)
- [Bicep Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.netapp/netappaccounts)

### SimpleChat
- [Original Repository](https://github.com/microsoft/simplechat)
- [SimpleChat Documentation](./docs/)

---

## Version
- SimpleChat Base: v0.237.004
- ANF Integration: v0.1.0 (in development)
