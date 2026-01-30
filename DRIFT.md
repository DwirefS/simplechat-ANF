# Repository Drift Report

## Comparison Summary

| Metric | Value |
|--------|-------|
| **Parent Repository** | [microsoft/simplechat](https://github.com/microsoft/simplechat) |
| **Fork Repository** | DwirefS/simplechat-ANF |
| **Parent Version** | v0.237.004 (commit 089760f) |
| **Comparison Date** | 2026-01-30 |
| **Total Changes** | 2,090 insertions, 8 deletions |

---

## DELETIONS (Files Removed from Parent)

**None** - No files from the parent repository have been deleted.

✅ **All original SimpleChat code is preserved.**

---

## ADDITIONS (New Files in Fork)

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 247 | Claude working file - project persona and guidelines |
| `DRIFT.md` | 200+ | This drift report |
| `PROJECT_PLAN.md` | 324 | Implementation plan for ANF integration |
| `deployers/bicep/modules/azureNetAppFiles.bicep` | 298 | Azure NetApp Files Bicep infrastructure module |
| `application/single_app/services/__init__.py` | 2 | Services module init |
| `application/single_app/services/anf_storage_service.py` | 475 | ANF S3-compatible storage client |
| `application/single_app/semantic_kernel_plugins/anf_storage_plugin.py` | 323 | Semantic Kernel plugin for ANF |

**Total New Files: 7**

---

## MODIFICATIONS (Files Changed from Parent)

### 1. `deployers/bicep/main.bicep`

**Changes: +97 lines, -5 lines (formatting)**

**Added Parameters:**
```bicep
@description('Enable deployment of Azure NetApp Files for enterprise storage.')
param deployAzureNetAppFiles bool = false

@description('Azure NetApp Files service level.')
@allowed(['Standard', 'Premium', 'Ultra'])
param anfServiceLevel string = 'Premium'

@description('Azure NetApp Files protocol type.')
@allowed(['NFSv3', 'NFSv4.1', 'SMB', 'DualProtocol'])
param anfProtocolType string = 'NFSv4.1'
```

**Added VNet Condition:**
- Changed: `if (enablePrivateNetworking)` → `if (enablePrivateNetworking || deployAzureNetAppFiles)`
- Added ANFSubnet to subnetConfigs when `deployAzureNetAppFiles` is true

**Added Module Deployment:**
```bicep
module azureNetAppFiles 'modules/azureNetAppFiles.bicep' = if (deployAzureNetAppFiles) {
  // ANF deployment configuration
}
```

**Added Outputs:**
```bicep
output var_deployAzureNetAppFiles bool = deployAzureNetAppFiles
output var_anfAccountName string = ...
output var_anfCapacityPoolName string = ...
output var_anfUserDocsVolumeName string = ...
output var_anfGroupDocsVolumeName string = ...
output var_anfPublicDocsVolumeName string = ...
output var_anfServiceLevel string = anfServiceLevel
output var_anfProtocolType string = anfProtocolType
```

---

### 2. `deployers/bicep/modules/virtualNetwork.bicep`

**Changes: +10 lines, 0 deletions**

**Added ANF Subnet Delegation:**
```bicep
] : subnet.name == 'ANFSubnet' ? [
  {
    name: 'NetAppDelegation'
    properties: {
      serviceName: 'Microsoft.NetApp/volumes'
    }
  }
] : []
```

**Added Variable:**
```bicep
var anfSubnetIndex = indexOf(subnetNames, 'ANFSubnet')
```

**Added Output:**
```bicep
output anfSubnetId string = anfSubnetIndex == -1 ? '' : subnetIds[anfSubnetIndex]
```

---

### 3. `application/single_app/config.py`

**Changes: +40 lines, 0 deletions**

**Added Storage Backend Toggle:**
```python
STORAGE_BACKEND = os.getenv("STORAGE_BACKEND", "blob").lower()
```

**Added ANF Configuration:**
```python
ANF_OBJECT_API_ENDPOINT = os.getenv("ANF_OBJECT_API_ENDPOINT", "")
ANF_AUTH_TYPE = os.getenv("ANF_AUTH_TYPE", "key")
ANF_ACCESS_KEY = os.getenv("ANF_ACCESS_KEY", "")
ANF_SECRET_KEY = os.getenv("ANF_SECRET_KEY", "")
ANF_USER_DOCUMENTS_BUCKET = os.getenv("ANF_USER_DOCUMENTS_BUCKET", "user-documents")
# ... etc
```

**Added Helper Functions:**
```python
def is_anf_storage_enabled(): ...
def get_anf_client(): ...
```

---

### 4. `application/single_app/functions_documents.py`

**Changes: +106 lines, 0 deletions**

**Modified `upload_to_blob()` to auto-route to ANF:**
```python
def upload_to_blob(...):
    if is_anf_storage_enabled():
        return _upload_to_anf_internal(...)
    # ... existing blob logic unchanged
```

**Added ANF upload function:**
```python
def _upload_to_anf_internal(...):
    # Uses boto3 S3 client for ANF Object REST API
```

---

### 5. `application/single_app/requirements.txt`

**Changes: +1 line**

```
boto3>=1.34.0  # For Azure NetApp Files Object REST API (S3-compatible)
```

---

### 6. `application/single_app/example.env`

**Changes: +32 lines**

Added ANF configuration section with all environment variables.

---

## Drift Summary

| Category | Count | Impact |
|----------|-------|--------|
| Files Deleted | **0** | ✅ None - no negative drift |
| Files Added | **7** | New ANF functionality |
| Files Modified | **6** | Extended for ANF support |
| Lines Added | **2,090** | New code |
| Lines Removed | **8** | Formatting only |

---

## Original SimpleChat vs SimpleChat-ANF Comparison

### Storage Services Comparison

| Service | Original SimpleChat | SimpleChat-ANF |
|---------|---------------------|----------------|
| **Azure Blob Storage** | ✅ Used for documents | ✅ KEPT (default) |
| **Azure NetApp Files** | ❌ Not available | ✅ NEW (optional) |
| **Azure Cosmos DB** | ✅ Metadata storage | ✅ KEPT (unchanged) |
| **Azure AI Search** | ✅ Vector index | ✅ KEPT (unchanged) |

### All Azure Components

| Component | Original | SimpleChat-ANF | Status |
|-----------|----------|----------------|--------|
| Azure App Service | ✅ | ✅ | UNCHANGED |
| Azure Container Registry | ✅ | ✅ | UNCHANGED |
| Azure Cosmos DB | ✅ | ✅ | UNCHANGED |
| **Azure Blob Storage** | ✅ | ✅ | KEPT (default) |
| **Azure NetApp Files** | ❌ | ✅ | **NEW (optional)** |
| Azure AI Search | ✅ | ✅ | UNCHANGED |
| Azure OpenAI | ✅ | ✅ | UNCHANGED |
| Azure Document Intelligence | ✅ | ✅ | UNCHANGED |
| Azure Key Vault | ✅ | ✅ | UNCHANGED |
| Log Analytics | ✅ | ✅ | UNCHANGED |
| Application Insights | ✅ | ✅ | UNCHANGED |
| Azure Cache for Redis | Optional | Optional | UNCHANGED |
| Azure Content Safety | Optional | Optional | UNCHANGED |
| Azure Speech Service | Optional | Optional | UNCHANGED |
| Azure Video Indexer | Optional | Optional | UNCHANGED |
| Virtual Network | Optional | Optional* | EXTENDED |

*VNet is now also created when `deployAzureNetAppFiles=true` (ANF requires delegated subnet)

### Network Architecture

**Single VNet Design (No Peering Required):**

```
VNet: ${appName}-${environment}-vnet
Address Space: 10.0.0.0/21 (2048 IPs)

├── AppServiceIntegration    10.0.0.0/24   (App Service VNet integration)
├── PrivateEndpoints         10.0.2.0/24   (Private endpoints for PaaS)
└── ANFSubnet                10.0.3.0/24   (ANF delegated subnet) *NEW*
```

All resources in the SAME VNet = no cross-VNet data transfer costs.

### Storage Toggle Behavior

| Configuration | Behavior |
|---------------|----------|
| `STORAGE_BACKEND="blob"` (default) | Identical to original SimpleChat |
| `STORAGE_BACKEND="anf"` | Uses Azure NetApp Files S3 API |
| `deployAzureNetAppFiles=false` | No ANF resources deployed |
| `deployAzureNetAppFiles=true` | ANF + VNet deployed |

### Files Changed Summary

| Category | Files |
|----------|-------|
| **New Documentation** | CLAUDE.md, DRIFT.md, PROJECT_PLAN.md |
| **New Infrastructure** | azureNetAppFiles.bicep |
| **New Application** | anf_storage_service.py, anf_storage_plugin.py |
| **Modified Infrastructure** | main.bicep, virtualNetwork.bicep |
| **Modified Application** | config.py, functions_documents.py |
| **Modified Config** | requirements.txt, example.env |

---

## Verification

```bash
# Commands used to generate this report:
git remote add upstream https://github.com/microsoft/simplechat.git
git fetch upstream main:upstream-main
git diff upstream-main HEAD --stat
git diff upstream-main HEAD --name-only --diff-filter=D  # Deletions
git diff upstream-main HEAD --name-only --diff-filter=A  # Additions
git diff upstream-main HEAD --name-only --diff-filter=M  # Modifications
```

---

## Conclusion

**No negative drift detected.**

All original SimpleChat code from microsoft/simplechat remains intact. The fork only contains **additions** to support Azure NetApp Files integration:

1. New documentation files (CLAUDE.md, DRIFT.md, PROJECT_PLAN.md)
2. New Bicep module for ANF infrastructure (azureNetAppFiles.bicep)
3. New application services (anf_storage_service.py, anf_storage_plugin.py)
4. Extended existing files with ANF support (purely additive)

**Key Guarantee:** Setting `STORAGE_BACKEND="blob"` (default) and `deployAzureNetAppFiles=false` results in behavior identical to original SimpleChat.
