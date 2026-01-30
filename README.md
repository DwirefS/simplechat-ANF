
![logo](./docs/images/logo-wide.png)

# Overview

The **Simple Chat Application** is a comprehensive, web-based platform designed to facilitate secure and context-aware interactions with generative AI models, specifically leveraging **Azure OpenAI**. Its central feature is **Retrieval-Augmented Generation (RAG)**, which significantly enhances AI interactions by allowing users to ground conversations in their own data. Users can upload personal ("Your Workspace") or shared group ("Group Workspaces") documents, which are processed using **Azure AI Document Intelligence**, chunked intelligently based on content type, vectorized via **Azure OpenAI Embeddings**, and indexed into **Azure AI Search** for efficient hybrid retrieval (semantic + keyword).

Built with modularity in mind, the application offers a suite of powerful **optional features** that can be enabled via administrative settings. These include integrating **Azure AI Content Safety** for governance, providing **Image Generation** capabilities (DALL-E), processing **Video** (via Azure Video Indexer) and **Audio** (via Azure Speech Service) files for RAG, implementing **Document Classification** schemes, collecting **User Feedback**, enabling **Conversation Archiving** for compliance, extracting **AI-driven Metadata**, and offering **Enhanced Citations** linked directly to source documents stored in Azure Storage.

The application utilizes **Azure Cosmos DB** for storing conversations, metadata, and settings, and is secured using **Azure Active Directory (Entra ID)** for authentication and fine-grained Role-Based Access Control (RBAC) via App Roles. Designed for enterprise use, it runs reliably on **Azure App Service** and supports deployment in both **Azure Commercial** and **Azure Government** cloud environments, offering a versatile tool for knowledge discovery, content generation, and collaborative AI-powered tasks within a secure, customizable, and Azure-native framework.

## Documentation

[Simple Chat Documentation | Simple Chat Documentation](https://microsoft.github.io/simplechat/)

## Quick Deploy

**📘 [Complete Step-by-Step Deployment Guide](./DEPLOY_STEPS.md)** ← Start here for full deployment instructions

[Bicep Module Reference](./deployers/bicep/README.md)

### Pre-Configuration:

The following procedure must be completed with a user that has permissions to create an application registration in the users Entra tenant. 

#### Create the application registration:

```powershell
cd ./deployers
```

Define your application name and your environment:

```
appName = 
```

```
environment = 
```

The following script will create an Entra Enterprise Application, with an App Registration named *\<appName\>*-*\<environment\>*-ar for the web service called *\<appName\>*-*\<environment\>*-app.  

> [!TIP]
>
> The web service name may be overriden with the `-AppServceName` parameter. 

> [!TIP]
>
> A different expiration date for the secret which defaults to 180 days with the `-SecretExpirationDays` parameter.

```powershell
.\Initialize-EntraApplication.ps1 -AppName "<appName>" -Environment "<environment>"  -AppRolesJsonPath "./azurecli/appRegistrationRoles.json"
```

> [!NOTE]
>
> Be sure to save this information as it will not be available after the window is closed.*

```========================================
App Registration Created Successfully!
Application Name:       <registered application name>
Client ID:              <clientID>
Tenant ID:              <tenantID>
Service Principal ID:   <servicePrincipalId>
Client Secret:          <clientSecret>
Secret Expiration:      <yyyy-mm-dd>
```

In addition, the script will note additional steps that must be taken for the app registration step to be completed.

1.  Grant Admin Consent for API Permissions:

    - Navigate to Azure Portal > Entra ID > App registrations
    - Find app: *\<registered application name\>*
    - Go to API permissions
    - Click 'Grant admin consent for [Tenant]'

2.  Assign Users/Groups to Enterprise Application:
    - Navigate to Azure Portal > Entra ID > Enterprise applications
    - Find app: *\<registered application name\>*
    - Go to Users and groups
    - Add user/group assignments with appropriate app roles

3.  Store the Client Secret Securely:
    - Save the client secret in Azure Key Vault or secure credential store
    - The secret value is shown above and will not be displayed again

#### Configure AZD Environment

Using the bash terminal in Visual Studio Code

```powershell
cd ./deployers
```

If you work with other Azure clouds, you may need to update your cloud like `azd config set cloud.name AzureUSGovernment` - more information here - [Use Azure Developer CLI in sovereign clouds | Microsoft Learn](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/sovereign-clouds)

```powershell
azd config set cloud.name AzureCloud
```

This will open a browser window that the user with Owner level permissions to the target subscription will need to authenticate with.

```powershell
azd auth login
```

Use the same value for the \<environment\> that was used in the application registration.

```powershell
azd env new <environment>
```

Select the new environment

```powershell
azd env select <environment>
```

This step will begin the deployment process.  

```powershell
azd up 
```

## Architecture

![Architecture](./docs/images/architecture.png)

## Features

- **Chat with AI**: Interact with an AI model based on Azure OpenAI’s GPT and Thinking models.
- **RAG with Hybrid Search**: Upload documents and perform hybrid searches (vector + keyword), retrieving relevant information from your files to augment AI responses.
- **Document Management**: Upload, store, and manage multiple versions of documents—personal ("Your Workspace") or group-level ("Group Workspaces").
- **Group Management**: Create and join groups to share access to group-specific documents, enabling collaboration with Role-Based Access Control (RBAC).
- **Ephemeral (Single-Convo) Documents**: Upload temporary documents available only during the current chat session, without persistent storage in Azure AI Search.
- **Conversation Archiving (Optional)**: Retain copies of user conversations—even after deletion from the UI—in a dedicated Cosmos DB container for audit, compliance, or legal requirements.
- **Content Safety (Optional)**: Integrate Azure AI Content Safety to review every user message *before* it reaches AI models, search indexes, or image generation services. Enforce custom filters and compliance policies, with an optional `SafetyAdmin` role for viewing violations.
- **Feedback System (Optional)**: Allow users to rate AI responses (thumbs up/down) and provide contextual comments on negative feedback. Includes user and admin dashboards, governed by an optional `FeedbackAdmin` role.
- **Bing Web Search (Optional)**: Augment AI responses with live Bing search results, providing up-to-date information. Configurable via Admin Settings.
- **Image Generation (Optional)**: Enable on-demand image creation using Azure OpenAI's DALL-E models, controlled via Admin Settings.
- **Video Extraction (Optional)**: Utilize Azure Video Indexer to transcribe speech and perform Optical Character Recognition (OCR) on video frames. Segments are timestamp-chunked for precise retrieval and enhanced citations linking back to the video timecode.
- **Audio Extraction (Optional)**: Leverage Azure Speech Service to transcribe audio files into timestamped text chunks, making audio content searchable and enabling enhanced citations linked to audio timecodes.
- **Document Classification (Optional)**: Admins define custom classification types and associated colors. Users tag uploaded documents with these labels, which flow through to AI conversations, providing lineage and insight into data sensitivity or type.
- **Enhanced Citation (Optional)**: Store processed, chunked files in Azure Storage (organized into user- and document-scoped folders). Display interactive citations in the UI—showing page numbers or timestamps—that link directly to the source document preview.
- **Metadata Extraction (Optional)**: Apply an AI model (configurable GPT model via Admin Settings) to automatically generate keywords, two-sentence summaries, and infer author/date for uploaded documents. Allows manual override for richer search context.
- **File Processing Logs (Optional)**: Enable verbose logging for all ingestion pipelines (workspaces and ephemeral chat uploads) to aid in debugging, monitoring, and auditing file processing steps.
- **Redis Cache (Optional)**: Integrate Azure Cache for Redis to provide a distributed, high-performance session store. This enables true horizontal scaling and high availability by decoupling user sessions from individual app instances.
- **Authentication & RBAC**: Secure access via Azure Active Directory (Entra ID) using MSAL. Supports Managed Identities for Azure service authentication, group-based controls, and custom application roles (`Admin`, `User`, `CreateGroup`, `SafetyAdmin`, `FeedbackAdmin`).
- **Supported File Types**:

  -   **Text**: `txt`, `md`, `html`, `json`, `xml`, `yaml`, `yml`, `log`
  -   **Documents**: `pdf`, `doc`, `docm`, `docx`, `pptx`, `xlsx`, `xlsm`, `xls`, `csv`
  -   **Images**: `jpg`, `jpeg`, `png`, `bmp`, `tiff`, `tif`, `heif`
  -   **Video**: `mp4`, `mov`, `avi`, `wmv`, `mkv`, `flv`, `mxf`, `gxf`, `ts`, `ps`, `3gp`, `3gpp`, `mpg`, `asf`, `m4v`, `isma`, `ismv`, `dvr-ms`
  -   **Audio**: `wav`, `m4a`

---

## Azure NetApp Files Integration (SimpleChat-ANF)

This fork extends SimpleChat with **Azure NetApp Files** as an enterprise storage option, demonstrating Azure NetApp File's powerful capabilities for AI and RAG workloads.

### Why Azure NetApp Files for AI Workloads?

Azure NetApp Files brings enterprise-grade storage capabilities that enhance AI applications:

| Capability | Benefit for AI/RAG |
|------------|-------------------|
| **Multi-Protocol Access** | Access the same data via NFS, SMB, and object REST API simultaneously |
| **Sub-Millisecond Latency** | Ultra-fast document retrieval for real-time AI responses |
| **Enterprise Performance** | Up to 4,500 MiB/s throughput per volume for large-scale processing |
| **Unified Data Platform** | No data duplication—train models, run inference, and serve users from one source |
| **Azure AI Integration** | Native integration with Azure AI Search, Databricks, OneLake |
| **Enterprise Compliance** | SAP HANA, GDPR, HIPAA, SOC certified |

### Enterprise Value Proposition

**Direct Access to Existing Enterprise Data**

Azure NetApp Files enables AI applications to directly consume data from enterprise NAS storage without requiring data movement or duplication:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Enterprise Data Workflow                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌──────────────┐                                                  │
│   │ Windows Users│──── SMB ────┐                                    │
│   │ (file drops) │             │                                    │
│   └──────────────┘             │                                    │
│                                ▼                                    │
│   ┌──────────────┐      ┌─────────────┐      ┌──────────────┐       │
│   │ Linux/Data   │─NFS─▶│Azure NetApp │      │              │       │
│   │              │      │Files Volume │◀─S3──│  AI Apps     │       │
│   │ Science      │      │  (one copy) │      │  (SimpleChat)│       │
│   └──────────────┘      └─────────────┘      └──────────────┘       │
│                                ▲                                    │
│   ┌──────────────┐             │                                    │
│   │ Backup/DR    │── Snapshot ─┘                                    │
│   │ Operations   │                                                  │
│   └──────────────┘                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Benefits:**

- **Zero Data Movement** — Documents uploaded to NFS/SMB shares are immediately accessible to AI applications via object REST API. No pipelines, no ETL, no waiting.

- **Single Source of Truth** — One copy of data serves all access patterns: file sharing, data science workflows, and AI/RAG applications.

- **Powered by NetApp ONTAP** — Enterprise-proven storage OS delivering instant snapshots, cross-region replication, storage tiering, and consistent sub-millisecond latency.

- **Simplify AI Data Architecture** — Eliminate the complexity of synchronizing data between file storage and object storage. Your enterprise file shares become AI-ready instantly.

- **Accelerate Time-to-Value** — Existing documents on corporate file shares can power RAG applications immediately. Drop a file on the share, query it in the chatbot seconds later.

### Multi-Protocol Architecture

Azure NetApp Files provides **three protocols to the same underlying data**:

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

**Use Cases:**
- **Object REST API**: Azure AI Search indexers, Azure Databricks, OneLake shortcuts
- **NFS**: Linux compute, Jupyter notebooks, ML training pipelines
- **SMB**: Windows desktops, enterprise file sharing, Active Directory integration

### Azure NetApp Files Service Tiers

Choose the performance tier that fits your workload:

| Tier | Throughput | Use Case |
|------|------------|----------|
| **Standard** | 16 MiB/s per TiB | Cost-optimized, archival |
| **Premium** | 64 MiB/s per TiB | General-purpose, recommended for RAG |
| **Ultra** | 128 MiB/s per TiB | High-performance, real-time AI |
| **Flexible** | Custom (1-4,500 MiB/s) | Independent throughput & capacity tuning |

### Deployment

#### Deploy with Azure NetApp Files Infrastructure

```powershell
azd up --parameters deployAzureNetAppFiles=true anfServiceLevel=Premium
```

This deploys:
- All standard SimpleChat resources (Blob Storage for documents)
- Azure NetApp Files account, capacity pool, and volumes
- VNet with dedicated Azure NetApp Files subnet (Microsoft.NetApp/volumes delegation)

#### Deploy without Azure NetApp Files (Original SimpleChat)

```powershell
azd up
```

Deploys standard SimpleChat with Azure Blob Storage only.

### Object REST API Setup (Manual Steps Required)

> **IMPORTANT**: The object REST API feature is currently in **PREVIEW** and requires manual configuration through the Azure Portal.

To enable object REST API access to Azure NetApp Files volumes:

#### Step 1: Enroll in Preview
- Submit a [waitlist request](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure) for the object REST API feature
- Activation takes approximately one week
- You will receive an email confirmation

#### Step 2: Generate SSL Certificate
- Navigate to your NetApp volume in Azure Portal
- Create a PEM-formatted SSL certificate
- The certificate Subject must be set to your endpoint: `CN=<IP or FQDN>`
- **You are responsible for certificate lifecycle management**

#### Step 3: Create a Bucket
- In Azure Portal, navigate to your NetApp volume
- Select **Buckets** from the volume menu
- Click **+Create** to create a new bucket
- Configure: bucket name, subdirectory path, UID/GID, permissions (Read or Read-Write)

#### Step 4: Generate Credentials
- After bucket creation, generate access credentials
- This creates an access key and secret access key
- **Store credentials securely—they cannot be retrieved again**

#### Step 5: Install Certificate on Clients
- Install the certificate on machines that will access the API
- **Windows**: Add to Trusted Root Certification Authorities
- **Linux**: Add to system trust store

#### Step 6: Access with S3-Compatible Clients
Microsoft officially documents these clients:
- **AWS CLI**: `aws s3 ls --endpoint-url https://<endpoint> s3://<bucket>/`
- **S3 Browser**: GUI tool for S3-compatible storage

When using AWS CLI, always use `us-east-1` as the default region name.

### Azure AI Services Integration

Once Object REST API is configured, Azure NetApp Files volumes can be accessed by:

| Service | Integration Method |
|---------|-------------------|
| **Azure AI Search** | S3-compatible data source indexer |
| **Azure Databricks** | Spark S3A connector |
| **OneLake** | Shortcuts to virtualize Azure NetApp Files into Microsoft Fabric |
| **Azure AI Foundry** | Direct access to training data |

### What's New in This Fork

| Category | Files Added/Modified |
|----------|---------------------|
| **Infrastructure** | `azureNetAppFiles.bicep` - Azure NetApp Files account, pool, volumes deployment |
| **VNet Integration** | Updated `virtualNetwork.bicep` with Azure NetApp Files subnet delegation |
| **Application** | `anf_storage_service.py` - Azure NetApp Files object REST API client |
| **Semantic Kernel** | `anf_storage_plugin.py` - AI agent plugin for Azure NetApp Files |
| **Configuration** | Updated `config.py` with storage backend toggle |
| **Documentation** | `CLAUDE.md`, `PROJECT_PLAN.md`, `DRIFT.md` |

### Storage Backend Configuration

Switch between Azure Blob Storage and Azure NetApp Files with environment variables:

```bash
# Default: Azure Blob Storage
STORAGE_BACKEND="blob"

# Use Azure NetApp Files object REST API
STORAGE_BACKEND="anf"
ANF_OBJECT_API_ENDPOINT="https://<your-endpoint>"
ANF_ACCESS_KEY="<from-azure-portal>"
ANF_SECRET_KEY="<from-azure-portal>"
```

### Compatibility

- ✅ **100% backwards compatible** with original SimpleChat
- ✅ **All existing features preserved** (see [DRIFT.md](./DRIFT.md) for full comparison)
- ✅ **Zero deletions** from parent repository
- ✅ **Azure Blob Storage** remains the default document storage

### Official Documentation

- [Azure NetApp Files Documentation](https://learn.microsoft.com/en-us/azure/azure-netapp-files/)
- [Configure object REST API](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure)
- [Access with S3-Compatible Clients](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-browser)
- [Object REST API Overview](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction)
- [Connect OneLake to Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-onelake)
- [Connect Azure Databricks to Azure NetApp Files](https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-databricks)

- [Project Drift Report](./DRIFT.md) - Detailed comparison with parent repo
