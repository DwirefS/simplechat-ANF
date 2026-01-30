# Repository Drift Report

## Comparison Summary

| Metric | Value |
|--------|-------|
| **Parent Repository** | [microsoft/simplechat](https://github.com/microsoft/simplechat) |
| **Fork Repository** | DwirefS/simplechat-ANF |
| **Parent Version** | v0.237.004 (commit 089760f) |
| **Comparison Date** | 2026-01-30 |
| **Total Changes** | 971 insertions, 5 deletions |

---

## DELETIONS (Files Removed from Parent)

**None** - No files from the parent repository have been deleted.

✅ **All original SimpleChat code is preserved.**

---

## ADDITIONS (New Files in Fork)

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 247 | Claude working file - project persona and guidelines |
| `PROJECT_PLAN.md` | 324 | Implementation plan for ANF integration |
| `deployers/bicep/modules/azureNetAppFiles.bicep` | 298 | Azure NetApp Files Bicep infrastructure module |

**Total New Files: 3**

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

## Drift Summary

| Category | Count | Impact |
|----------|-------|--------|
| Files Deleted | **0** | ✅ None - no negative drift |
| Files Added | **3** | New ANF functionality |
| Files Modified | **2** | Extended for ANF support |
| Lines Added | **971** | New code |
| Lines Removed | **5** | Formatting only |

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

1. New documentation files (CLAUDE.md, PROJECT_PLAN.md)
2. New Bicep module for ANF infrastructure
3. Extended existing Bicep files with ANF parameters and deployment logic

The fork is ready to continue with Phase 2 (application code integration).
