# SimpleChat + Azure NetApp Files Integration - Project Plan

## Executive Summary

This project integrates Azure NetApp Files (ANF) as the enterprise storage layer for the SimpleChat AI chatbot application. The integration leverages ANF's Object REST API (S3-compatible) to replace Azure Blob Storage while enabling multi-protocol access (NFS/SMB) for enterprise workflows.

---

## Project Phases

### Phase 1: Infrastructure Foundation (Week 1)

#### Tasks

| # | Task | Status | Priority | Assignee |
|---|------|--------|----------|----------|
| 1.1 | Create Azure NetApp Files Bicep module | ✅ Done | High | - |
| 1.2 | Add ANF subnet to virtual network module | 🔲 Pending | High | - |
| 1.3 | Update main.bicep with ANF deployment | 🔲 Pending | High | - |
| 1.4 | Create ANF Terraform module | 🔲 Pending | Medium | - |
| 1.5 | Update deployment parameters | 🔲 Pending | High | - |
| 1.6 | Test infrastructure deployment | 🔲 Pending | High | - |

#### Deliverables
- [x] `deployers/bicep/modules/azureNetAppFiles.bicep`
- [ ] Updated `deployers/bicep/modules/virtualNetwork.bicep`
- [ ] Updated `deployers/bicep/main.bicep`
- [ ] `deployers/terraform/modules/azure_netapp_files.tf`

---

### Phase 2: Application Integration (Week 2)

#### Tasks

| # | Task | Status | Priority | Assignee |
|---|------|--------|----------|----------|
| 2.1 | Create ANF storage service module | 🔲 Pending | High | - |
| 2.2 | Create ANF Semantic Kernel plugin | 🔲 Pending | High | - |
| 2.3 | Add storage abstraction layer | 🔲 Pending | High | - |
| 2.4 | Update document upload functions | 🔲 Pending | High | - |
| 2.5 | Update document download functions | 🔲 Pending | High | - |
| 2.6 | Update enhanced citations module | 🔲 Pending | Medium | - |
| 2.7 | Add boto3 to requirements.txt | 🔲 Pending | High | - |

#### Deliverables
- [ ] `application/single_app/services/anf_storage_service.py`
- [ ] `application/single_app/semantic_kernel_plugins/anf_storage_plugin.py`
- [ ] `application/single_app/services/storage_factory.py`
- [ ] Updated `application/single_app/functions_documents.py`
- [ ] Updated `application/single_app/requirements.txt`

---

### Phase 3: Configuration & Admin UI (Week 3)

#### Tasks

| # | Task | Status | Priority | Assignee |
|---|------|--------|----------|----------|
| 3.1 | Add ANF environment variables | 🔲 Pending | High | - |
| 3.2 | Update config.py for ANF | 🔲 Pending | High | - |
| 3.3 | Add ANF settings to admin UI | 🔲 Pending | Medium | - |
| 3.4 | Create storage toggle (Blob/ANF) | 🔲 Pending | Medium | - |
| 3.5 | Update example.env template | 🔲 Pending | Medium | - |
| 3.6 | Add ANF health check endpoint | 🔲 Pending | Low | - |

#### Deliverables
- [ ] Updated `application/single_app/config.py`
- [ ] Updated `application/single_app/example.env`
- [ ] Updated admin control center UI
- [ ] ANF connection test endpoint

---

### Phase 4: Azure AI Search Integration (Week 4)

#### Tasks

| # | Task | Status | Priority | Assignee |
|---|------|--------|----------|----------|
| 4.1 | Configure ANF as AI Search data source | 🔲 Pending | High | - |
| 4.2 | Update search indexer for ANF | 🔲 Pending | High | - |
| 4.3 | Test vector search with ANF data | 🔲 Pending | High | - |
| 4.4 | Update RAG retrieval functions | 🔲 Pending | Medium | - |
| 4.5 | Performance benchmarking | 🔲 Pending | Medium | - |

#### Deliverables
- [ ] ANF-based Azure AI Search data source
- [ ] Updated indexer configuration
- [ ] Performance benchmark report

---

### Phase 5: Testing & Documentation (Week 5)

#### Tasks

| # | Task | Status | Priority | Assignee |
|---|------|--------|----------|----------|
| 5.1 | Unit tests for ANF service | 🔲 Pending | High | - |
| 5.2 | Integration tests | 🔲 Pending | High | - |
| 5.3 | End-to-end testing | 🔲 Pending | High | - |
| 5.4 | Update deployment documentation | 🔲 Pending | Medium | - |
| 5.5 | Create demo scripts | 🔲 Pending | Medium | - |
| 5.6 | Record demo video | 🔲 Pending | Low | - |

#### Deliverables
- [ ] Test suite for ANF integration
- [ ] Updated README.md
- [ ] Demo scripts and documentation
- [ ] Demo video

---

## Technical Specifications

### Azure NetApp Files Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| Service Level | Premium | Sub-millisecond latency |
| Capacity Pool | 4 TiB | Minimum required |
| Volume Size | 100 GiB | Per document bucket |
| Protocol | NFSv4.1 | Primary access |
| Object REST API | Enabled | S3-compatible access |
| Cool Access | Optional | Cost optimization |

### Volume Structure

```
ANF Account: simplechat-<env>-anf
└── Capacity Pool: simplechat-<env>-pool (4 TiB, Premium)
    ├── Volume: user-documents (100 GiB)
    │   └── Bucket: user-documents
    ├── Volume: group-documents (100 GiB)
    │   └── Bucket: group-documents
    └── Volume: public-documents (100 GiB)
        └── Bucket: public-documents
```

### Network Requirements

| Subnet | CIDR | Purpose |
|--------|------|---------|
| ANFSubnet | 10.0.3.0/24 | Delegated to Microsoft.NetApp/volumes |
| AppServiceIntegration | 10.0.0.0/24 | App Service VNet integration |
| PrivateEndpoints | 10.0.2.0/24 | Private endpoints |

---

## Code Changes Summary

### New Files

| File | Purpose |
|------|---------|
| `deployers/bicep/modules/azureNetAppFiles.bicep` | ANF infrastructure |
| `application/single_app/services/anf_storage_service.py` | ANF storage operations |
| `application/single_app/semantic_kernel_plugins/anf_storage_plugin.py` | ANF Semantic Kernel plugin |
| `application/single_app/services/storage_factory.py` | Storage abstraction |

### Modified Files

| File | Changes |
|------|---------|
| `deployers/bicep/main.bicep` | Add ANF module deployment |
| `deployers/bicep/modules/virtualNetwork.bicep` | Add ANF subnet |
| `application/single_app/config.py` | ANF configuration |
| `application/single_app/functions_documents.py` | Storage abstraction |
| `application/single_app/route_backend_control_center.py` | ANF admin settings |
| `application/single_app/requirements.txt` | Add boto3 |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Object REST API regional availability | Medium | High | Check region support before deployment |
| Performance degradation | Low | Medium | Use Premium/Ultra tier |
| Cost overrun | Medium | Medium | Use cool access tier, right-size volumes |
| Integration complexity | Medium | Medium | Implement storage abstraction layer |
| Breaking existing functionality | Low | High | Maintain backwards compatibility with toggle |

---

## Success Criteria

1. **Functional**: Documents upload/download via ANF Object REST API
2. **Performance**: Latency <= 5ms for document operations
3. **Compatibility**: Existing features work unchanged
4. **Multi-Protocol**: Same data accessible via NFS and S3 API
5. **Demo Ready**: Clear demonstration of ANF value proposition

---

## Dependencies

### Azure Services
- Azure NetApp Files (Standard/Premium/Ultra)
- Azure Virtual Network with delegated subnet
- Azure AI Search (for indexer integration)
- Azure Key Vault (for credential storage)

### Python Packages
- `boto3` >= 1.34.0 (S3 SDK)
- `botocore` >= 1.34.0

### Bicep API Versions
- `Microsoft.NetApp/netAppAccounts@2025-01-01`
- `Microsoft.NetApp/netAppAccounts/capacityPools@2025-01-01`
- `Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01`

---

## Contact & Resources

### Documentation
- [CLOUD.md](./CLOUD.md) - Technical architecture
- [Azure NetApp Files Docs](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Object REST API Guide](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)

### Repository
- Original: [microsoft/simplechat](https://github.com/microsoft/simplechat)
- Fork: [DwirefS/simplechat-ANF](https://github.com/DwirefS/simplechat-ANF)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-29 | Claude | Initial project plan |
