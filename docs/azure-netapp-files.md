---
title: "Azure NetApp Files Integration"
---

## Azure NetApp Files Overview

<div style="text-align: center; margin: 2rem 0;">
  <img src="https://learn.microsoft.com/en-us/azure/azure-netapp-files/media/azure-netapp-files/azure-netapp-files-logo.png" alt="Azure NetApp Files" style="max-width: 250px;">
</div>

**Azure NetApp Files** is a first-party Azure service powered by **NetApp ONTAP** - the world's most trusted enterprise storage operating system. It delivers enterprise-grade file storage with the simplicity and scale of Azure.

---

## Multi-Protocol Architecture

Azure NetApp Files provides **three protocols to the same underlying data**, enabling unified access across all workloads:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure NetApp Files Volume                     │
│                      (Single Data Source)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│   │  Object REST │   │     NFS      │   │     SMB      │        │
│   │     API      │   │  (v3/v4.1)   │   │   (2.x/3.x)  │        │
│   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘        │
│          │                  │                  │                 │
│          ▼                  ▼                  ▼                 │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│   │ Azure AI     │   │ Data Science │   │ Windows      │        │
│   │ Services     │   │ Workloads    │   │ Clients      │        │
│   └──────────────┘   └──────────────┘   └──────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Protocol Use Cases

| Protocol | Primary Use Cases |
|----------|-------------------|
| **Object REST API** | Azure AI Search indexers, Azure Databricks, OneLake shortcuts, cloud-native applications |
| **NFS (v3/v4.1)** | Linux compute, Jupyter notebooks, ML training pipelines, POSIX-compliant workloads |
| **SMB (2.x/3.x)** | Windows desktops, enterprise file sharing, Active Directory integration |

---

## Object REST API (S3-Compatible)

The **Object REST API** enables Azure NetApp Files volumes to be accessed using the S3 protocol, making enterprise NAS data available to cloud-native services.

### Supported Clients

Microsoft officially documents these S3-compatible clients:

| Client | Use Case |
|--------|----------|
| **AWS CLI** | Command-line access, scripting |
| **S3 Browser** | GUI-based file management |
| **boto3** | Python applications (same S3 protocol as AWS CLI) |

### Configuration Steps

1. **Enroll in Preview** - Submit waitlist request (activation takes ~1 week)
2. **Generate SSL Certificate** - PEM format, CN must match endpoint
3. **Create Bucket** - Map to volume subdirectory
4. **Generate Credentials** - Access key + secret key
5. **Install Certificate** - Add to client trust store
6. **Connect** - Use S3-compatible tools

> **Note:** Object REST API is currently in **PREVIEW**. See [official documentation](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure) for latest status.

---

## Azure AI Services Integration

Azure NetApp Files integrates natively with Azure's AI ecosystem:

### Azure AI Search

Create an indexer that crawls ANF volumes via Object REST API:

```
ANF Volume → Object REST API → AI Search Indexer → Vector Index → RAG Queries
```

[Documentation: Connect Azure AI Search to ANF](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)

### Azure Databricks

Access ANF data using the Spark S3A connector:

```python
# Databricks notebook
df = spark.read.format("parquet") \
    .option("fs.s3a.endpoint", "https://<anf-endpoint>") \
    .load("s3a://<bucket>/data/")
```

[Documentation: Connect Azure Databricks to ANF](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-databricks)

### Microsoft Fabric OneLake

Create shortcuts to virtualize ANF data in your lakehouse:

```
ANF Volume → OneLake Shortcut → Fabric Lakehouse → Power BI / Notebooks
```

[Documentation: Connect OneLake to ANF](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-onelake)

---

## Performance Tiers

Choose the tier that matches your workload requirements:

| Tier | Throughput | Latency | Use Case |
|------|------------|---------|----------|
| **Standard** | 16 MiB/s per TiB | < 1ms | Cost-optimized, archival, backup |
| **Premium** | 64 MiB/s per TiB | < 1ms | General-purpose, RAG workloads |
| **Ultra** | 128 MiB/s per TiB | < 1ms | Real-time AI, high-throughput |
| **Flexible** | 1-4,500 MiB/s | < 1ms | Custom throughput/capacity ratio |

All tiers deliver **sub-millisecond latency** for enterprise workloads.

---

## ONTAP Enterprise Features

Azure NetApp Files is powered by **NetApp ONTAP**, bringing decades of enterprise storage innovation to Azure:

### Data Protection

- **Instant Snapshots** - Point-in-time copies without performance impact
- **Cross-Region Replication** - Disaster recovery across Azure regions
- **Backup to Azure Blob** - Long-term retention to cost-effective storage

### Efficiency

- **Deduplication** - Eliminate redundant data blocks
- **Compression** - Reduce storage footprint
- **Cool Access Tier** - Automatic tiering for cold data

### Security & Compliance

- **Encryption at Rest** - AES-256 encryption
- **Encryption in Transit** - TLS/SSL for all protocols
- **Active Directory Integration** - Enterprise identity management
- **Compliance Certifications** - SAP HANA, GDPR, HIPAA, SOC 1/2

---

## SimpleChat-ANF Integration

This project demonstrates ANF as the storage backend for SimpleChat's RAG pipeline:

```
User Upload → Flask App → ANF Object REST API → ANF Volume
                                                    │
AI Search Indexer ←────────────────────────────────┘
       │
       ▼
Vector Index → RAG Query → Azure OpenAI → Response
```

### Storage Backend Toggle

Switch between Azure Blob Storage and ANF with a single environment variable:

```bash
# Use Azure Blob Storage (default)
STORAGE_BACKEND="blob"

# Use Azure NetApp Files
STORAGE_BACKEND="anf"
ANF_OBJECT_API_ENDPOINT="https://<endpoint>"
ANF_ACCESS_KEY="<access-key>"
ANF_SECRET_KEY="<secret-key>"
```

### Files Added

| File | Purpose |
|------|---------|
| `services/anf_storage_service.py` | ANF Object REST API client |
| `semantic_kernel_plugins/anf_storage_plugin.py` | AI agent plugin |
| `deployers/bicep/modules/azureNetAppFiles.bicep` | Infrastructure as Code |

---

## Official Documentation

### Azure NetApp Files

- [Product Overview](https://learn.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-introduction)
- [Object REST API Introduction](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [Configure Object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure)
- [Performance Tiers](https://learn.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-service-levels)
- [Bicep/ARM Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.netapp/netappaccounts)

### Integration Guides

- [Connect Azure Databricks](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-databricks)
- [Connect OneLake](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-onelake)
- [How ANF Powers Azure AI Services](https://techcommunity.microsoft.com/blog/azurearchitectureblog/how-azure-netapp-files-object-rest-api-powers-azure-and-isv-data-and-ai-services/4459545)

---

<div style="text-align: center; margin-top: 3rem; padding: 2rem; background: #f8f9fa; border-radius: 8px;">
  <p style="font-size: 1.1rem;"><strong>Azure + NetApp = Better Together</strong></p>
  <p>Enterprise storage. Cloud scale. AI ready.</p>
</div>
