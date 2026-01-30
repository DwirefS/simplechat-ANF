---
layout: page
title: "SimpleChat-ANF | Azure AI Accelerator"
description: "Enterprise-grade AI chatbot accelerator powered by Azure NetApp Files and Azure OpenAI"
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="https://learn.microsoft.com/en-us/azure/azure-netapp-files/media/azure-netapp-files/azure-netapp-files-logo.png" alt="Azure NetApp Files" style="max-width: 300px; margin-bottom: 1rem;">
  <h2 style="color: #0078d4;">Azure + NetApp = Better Together</h2>
</div>

## Azure AI Accelerator with Enterprise Storage

**SimpleChat-ANF** extends Microsoft's [SimpleChat](https://github.com/microsoft/simplechat) demo with **Azure NetApp Files**, delivering enterprise-grade storage for AI and RAG workloads.

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin: 2rem 0;">

<div style="border: 1px solid #ddd; border-radius: 8px; padding: 1.5rem; background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);">
<h3 style="margin-top: 0; color: #0078d4;">Multi-Protocol Access</h3>
<p>Access the same data simultaneously via <strong>NFS</strong>, <strong>SMB</strong>, and <strong>Object REST API</strong> (S3-compatible). One copy of data serves all workloads.</p>
</div>

<div style="border: 1px solid #ddd; border-radius: 8px; padding: 1.5rem; background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);">
<h3 style="margin-top: 0; color: #0078d4;">Zero Data Movement</h3>
<p>Enterprise NAS data is directly accessible to AI applications. No ETL pipelines, no data duplication, no waiting.</p>
</div>

<div style="border: 1px solid #ddd; border-radius: 8px; padding: 1.5rem; background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);">
<h3 style="margin-top: 0; color: #0078d4;">Powered by ONTAP</h3>
<p>NetApp ONTAP delivers instant snapshots, cross-region replication, storage tiering, and consistent sub-millisecond latency.</p>
</div>

<div style="border: 1px solid #ddd; border-radius: 8px; padding: 1.5rem; background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);">
<h3 style="margin-top: 0; color: #0078d4;">Azure AI Integration</h3>
<p>Native integration with Azure AI Search, Azure Databricks, Microsoft Fabric OneLake, and Azure AI Foundry.</p>
</div>

</div>

---

## Enterprise Data Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Enterprise Data Workflow                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────┐                                                   │
│   │ Windows Users│──── SMB ────┐                                     │
│   │ (file drops) │             │                                     │
│   └──────────────┘             │                                     │
│                                ▼                                     │
│   ┌──────────────┐      ┌─────────────┐      ┌──────────────┐       │
│   │ Linux/Data   │─NFS─▶│  ANF Volume │◀─S3──│  AI Apps     │       │
│   │ Science      │      │  (one copy) │      │  (SimpleChat)│       │
│   └──────────────┘      └─────────────┘      └──────────────┘       │
│                                ▲                                     │
│   ┌──────────────┐             │                                     │
│   │ Backup/DR    │── Snapshot ─┘                                     │
│   │ Operations   │                                                   │
│   └──────────────┘                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**The value:** Documents on your enterprise file shares can power RAG applications immediately. Drop a file on the SMB share, query it in the AI chatbot seconds later.

---

## Why Azure NetApp Files for AI?

| Capability | Benefit |
|------------|---------|
| **Sub-Millisecond Latency** | Ultra-fast document retrieval for real-time AI responses |
| **Up to 4,500 MiB/s Throughput** | Large-scale document processing and model training |
| **Unified Data Platform** | Train models, run inference, serve users from one data source |
| **Enterprise Compliance** | SAP HANA, GDPR, HIPAA, SOC certified |
| **Azure-Native** | First-party Azure service, fully integrated with Azure ecosystem |

---

## Service Tiers

| Tier | Throughput | Use Case |
|------|------------|----------|
| **Standard** | 16 MiB/s per TiB | Cost-optimized, archival |
| **Premium** | 64 MiB/s per TiB | General-purpose, recommended for RAG |
| **Ultra** | 128 MiB/s per TiB | High-performance, real-time AI |
| **Flexible** | 1-4,500 MiB/s | Independent throughput & capacity tuning |

---

## Quick Start

### Deploy with Azure NetApp Files

```powershell
# Clone the repository
git clone https://github.com/DwirefS/simplechat-ANF.git
cd simplechat-ANF/deployers

# Deploy infrastructure with ANF
azd up --parameters deployAzureNetAppFiles=true anfServiceLevel=Premium
```

### Configure Object REST API

After deployment, enable the Object REST API in Azure Portal:

1. **Enroll in Preview** - Submit [waitlist request](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure)
2. **Generate Certificate** - Create PEM-formatted SSL certificate
3. **Create Bucket** - Configure bucket on ANF volume
4. **Generate Credentials** - Create access key and secret key
5. **Configure Application** - Set environment variables

See the [Complete Deployment Guide](https://github.com/DwirefS/simplechat-ANF/blob/main/DEPLOY_STEPS.md) for detailed instructions.

---

## Architecture

![Architecture](./images/architecture.png)

---

## Azure AI Services Integration

| Service | Integration |
|---------|-------------|
| **Azure AI Search** | S3-compatible data source indexer for RAG |
| **Azure Databricks** | Spark S3A connector for analytics |
| **Microsoft Fabric OneLake** | Shortcuts to virtualize ANF data |
| **Azure AI Foundry** | Direct access to training data |
| **Azure OpenAI** | LLM for chat responses |
| **Azure Document Intelligence** | PDF and image extraction |

---

## Resources

### Official Documentation

- [Azure NetApp Files Documentation](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Object REST API Overview](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [Configure Object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure)
- [Connect OneLake to ANF](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-onelake)
- [Connect Azure Databricks to ANF](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-databricks)

### Project Resources

- [GitHub Repository](https://github.com/DwirefS/simplechat-ANF)
- [Deployment Guide](https://github.com/DwirefS/simplechat-ANF/blob/main/DEPLOY_STEPS.md)
- [Parent Repository (Microsoft SimpleChat)](https://github.com/microsoft/simplechat)

---

## About This Project

**SimpleChat-ANF** is an accelerator that pairs Microsoft's SimpleChat AI demo with Azure NetApp Files enterprise storage. This project demonstrates how existing enterprise NAS data can directly power AI applications without data movement or duplication.

### Key Points

- **100% backwards compatible** with original SimpleChat
- **Zero deletions** from parent repository
- **Azure Blob Storage** remains available as default option
- **Open source** under MIT License

---

<div style="text-align: center; margin-top: 3rem; padding: 2rem; background: #f8f9fa; border-radius: 8px;">
  <p style="font-size: 1.2rem; margin-bottom: 1rem;"><strong>Ready to get started?</strong></p>
  <a href="https://github.com/DwirefS/simplechat-ANF" style="display: inline-block; background: #0078d4; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; margin-right: 1rem;">View on GitHub</a>
  <a href="https://github.com/DwirefS/simplechat-ANF/blob/main/DEPLOY_STEPS.md" style="display: inline-block; background: #28a745; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none;">Deployment Guide</a>
</div>
