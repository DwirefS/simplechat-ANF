# SimpleChat-ANF Deployment Guide

Complete step-by-step instructions to deploy SimpleChat with Azure NetApp Files integration.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone the Repository](#2-clone-the-repository)
3. [Create Entra ID App Registration](#3-create-entra-id-app-registration)
4. [Configure Azure Developer CLI](#4-configure-azure-developer-cli)
5. [Deploy Infrastructure](#5-deploy-infrastructure)
6. [Configure Azure NetApp Files Object REST API](#6-configure-azure-netapp-files-object-rest-api)
7. [Configure the Application](#7-configure-the-application)
8. [Verify Deployment](#8-verify-deployment)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

### 1.1 Required Tools

Install these tools on your local machine:

#### Azure CLI
```bash
# Windows (PowerShell as Administrator)
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Verify installation:
```bash
az --version
```
You should see version 2.50.0 or higher.

#### Azure Developer CLI (azd)
```bash
# Windows (PowerShell as Administrator)
winget install Microsoft.Azd

# macOS
brew install azure/tap/azd

# Linux
curl -fsSL https://aka.ms/install-azd.sh | bash
```

Verify installation:
```bash
azd version
```
You should see version 1.5.0 or higher.

#### PowerShell 7+
```bash
# Windows
winget install Microsoft.PowerShell

# macOS
brew install powershell

# Linux (Ubuntu)
sudo apt-get install -y powershell
```

Verify installation:
```bash
pwsh --version
```

#### Git
```bash
# Windows
winget install Git.Git

# macOS
brew install git

# Linux
sudo apt-get install git
```

### 1.2 Required Azure Permissions

You need these permissions in your Azure subscription:

| Permission | Why |
|------------|-----|
| **Owner** or **Contributor** on Subscription | Deploy resources |
| **User Access Administrator** | Assign roles to managed identities |
| **Application Administrator** in Entra ID | Create app registrations |

To check your permissions:
1. Go to https://portal.azure.com
2. Click **Subscriptions** in the left menu
3. Click your subscription
4. Click **Access control (IAM)**
5. Click **View my access**
6. Verify you have Owner or Contributor role

### 1.3 Azure NetApp Files Prerequisites

**IMPORTANT**: Azure NetApp Files requires:

1. **Register the NetApp Resource Provider**:
   ```bash
   az provider register --namespace Microsoft.NetApp
   ```

   Check registration status (wait until "Registered"):
   ```bash
   az provider show --namespace Microsoft.NetApp --query "registrationState"
   ```

2. **Request Object REST API Preview Access** (if using Object REST API):
   - Go to: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure
   - Click the waitlist link and submit your request
   - Wait for email confirmation (~1 week)

---

## 2. Clone the Repository

### 2.1 Open Terminal

- **Windows**: Press `Win + X`, select "Terminal" or "PowerShell"
- **macOS**: Press `Cmd + Space`, type "Terminal", press Enter
- **Linux**: Press `Ctrl + Alt + T`

### 2.2 Navigate to Your Projects Folder

```bash
# Windows
cd C:\Projects

# macOS/Linux
cd ~/Projects
```

If the folder doesn't exist, create it:
```bash
# Windows
mkdir C:\Projects
cd C:\Projects

# macOS/Linux
mkdir -p ~/Projects
cd ~/Projects
```

### 2.3 Clone the Repository

```bash
git clone https://github.com/DwirefS/simplechat-ANF.git
cd simplechat-ANF
```

You should see output like:
```
Cloning into 'simplechat-ANF'...
remote: Enumerating objects: 1234, done.
...
```

---

## 3. Create Entra ID App Registration

This step creates the authentication for your application.

### 3.1 Navigate to Deployers Folder

```bash
cd deployers
```

### 3.2 Define Your Application Name

Choose a unique name for your application. Replace `<your-app-name>` with your choice (e.g., `simplechat`, `mycompany-chat`).

**PowerShell:**
```powershell
$appName = "<your-app-name>"
$environment = "prod"
```

**Bash:**
```bash
export appName="<your-app-name>"
export environment="prod"
```

### 3.3 Run the App Registration Script

**PowerShell:**
```powershell
.\Initialize-EntraApplication.ps1 -AppName $appName -Environment $environment -AppRolesJsonPath "./azurecli/appRegistrationRoles.json"
```

**IMPORTANT**: Save the output! You will see:
```
========================================
App Registration Created Successfully!
Application Name:       simplechat-prod-ar
Client ID:              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Tenant ID:              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Service Principal ID:   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Client Secret:          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Secret Expiration:      2025-07-30
========================================
```

**Copy these values to a secure location immediately!** The Client Secret cannot be retrieved again.

### 3.4 Grant Admin Consent

1. Open https://portal.azure.com
2. Click the search bar at the top
3. Type "App registrations" and click it
4. Click your app (e.g., `simplechat-prod-ar`)
5. In the left menu, click **API permissions**
6. Click the blue button **Grant admin consent for [Your Tenant]**
7. Click **Yes** in the confirmation popup
8. Wait until all permissions show green checkmarks

### 3.5 Assign Users to the Application

1. In the Azure Portal search bar, type "Enterprise applications"
2. Click **Enterprise applications**
3. Find and click your app (e.g., `simplechat-prod-ar`)
4. In the left menu, click **Users and groups**
5. Click **+ Add user/group**
6. Click **Users** → Select yourself → Click **Select**
7. Click **Select a role** → Choose **Admin** → Click **Select**
8. Click **Assign**

---

## 4. Configure Azure Developer CLI

### 4.1 Set Azure Cloud (if needed)

For Azure Commercial (default):
```bash
azd config set cloud.name AzureCloud
```

For Azure Government:
```bash
azd config set cloud.name AzureUSGovernment
```

### 4.2 Login to Azure

```bash
azd auth login
```

A browser window will open:
1. Select your Azure account
2. If prompted, enter your password
3. Click **Accept** for permissions
4. Close the browser tab when you see "You have logged in"

### 4.3 Create a New Environment

```bash
azd env new prod
```

When prompted:
- **Select an Azure Subscription**: Use arrow keys to select, press Enter
- **Select a location**: Choose a region that supports Azure NetApp Files (e.g., `eastus`, `westus2`, `westeurope`)

### 4.4 Select the Environment

```bash
azd env select prod
```

---

## 5. Deploy Infrastructure

### 5.1 Deploy WITHOUT Azure NetApp Files (Quick Start)

If you want to deploy the basic SimpleChat without ANF:

```bash
azd up
```

This takes 15-30 minutes. Skip to [Section 8](#8-verify-deployment).

### 5.2 Deploy WITH Azure NetApp Files

```bash
azd up
```

When prompted for parameters, enter:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `deployAzureNetAppFiles` | `true` | Deploys ANF resources |
| `anfServiceLevel` | `Premium` | Performance tier (Standard/Premium/Ultra/Flexible) |
| `anfProtocolType` | `NFSv4.1` | Protocol for volumes |

**Alternative**: Pass parameters directly:
```bash
azd up --parameter deployAzureNetAppFiles=true --parameter anfServiceLevel=Premium
```

### 5.3 Wait for Deployment

The deployment takes 20-40 minutes. You'll see progress like:
```
Provisioning Azure resources (azd provision)
...
(✓) Done: Resource group: rg-simplechat-prod
(✓) Done: Azure Cosmos DB account
(✓) Done: Azure OpenAI
(✓) Done: Azure NetApp Files account
...
```

### 5.4 Note the Outputs

When deployment completes, you'll see outputs. Save these:
```
Outputs:
  AZURE_COSMOS_ENDPOINT: https://cosmos-xxx.documents.azure.com:443/
  AZURE_OPENAI_ENDPOINT: https://oai-xxx.openai.azure.com/
  ANF_ACCOUNT_NAME: simplechat-prod-anf
  ANF_VOLUME_MOUNT_IP: 10.0.2.4
  ...
```

---

## 6. Configure Azure NetApp Files Object REST API

**IMPORTANT**: This section requires manual Azure Portal steps. The Object REST API is in preview.

### 6.1 Verify Preview Access

Before proceeding, ensure you have Object REST API preview access:
1. You should have received a confirmation email
2. If not, wait or contact Azure support

### 6.2 Navigate to Your NetApp Account

1. Open https://portal.azure.com
2. Click the search bar at the top
3. Type "Azure NetApp Files" and click it
4. Click your NetApp account (e.g., `simplechat-prod-anf`)

### 6.3 Navigate to a Volume

1. In the left menu, click **Volumes**
2. Click on `user-documents` volume (or whichever volume you want to enable)

### 6.4 Generate SSL Certificate

1. In the volume menu, click **Buckets**
2. If you see a message about certificates, click **Generate certificate**
3. Fill in the certificate form:
   - **Common Name (CN)**: Enter the IP address of your volume (from deployment outputs, e.g., `10.0.2.4`)
   - **Validity**: 365 days (or your preference)
4. Click **Generate**
5. **Download the certificate** - Click the download button
6. Save the `.pem` file to a secure location

### 6.5 Create a Bucket

1. Still in the **Buckets** section, click **+ Create**
2. Fill in the form:
   - **Bucket name**: `user-documents`
   - **Path**: `/` (root of volume) or leave empty
   - **User ID (UID)**: `1000`
   - **Group ID (GID)**: `1000`
   - **Permissions**: `Read-Write`
3. Click **Create**
4. Repeat for `group-documents` and `public-documents` buckets

### 6.6 Generate Access Credentials

1. Click on the bucket you just created (e.g., `user-documents`)
2. Click **Generate access keys**
3. **IMMEDIATELY COPY AND SAVE**:
   - **Access Key ID**: `AKIAXXXXXXXXXXXXXXXX`
   - **Secret Access Key**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**WARNING**: The Secret Access Key is shown ONLY ONCE. If you lose it, you must generate new keys.

### 6.7 Get the Object REST API Endpoint

1. In the bucket details, find **Endpoint URL**
2. Copy it - it looks like: `https://10.0.2.4:443` or `https://anf-endpoint.region.azure.com`
3. Save this value

### 6.8 Install Certificate on App Service

1. In Azure Portal, search for "App Services"
2. Click your App Service (e.g., `simplechat-prod-app`)
3. In the left menu, under **Settings**, click **Certificates**
4. Click **+ Add certificate**
5. Select **Upload certificate (.pfx)**
6. You'll need to convert your PEM to PFX first:

**Convert PEM to PFX (run locally):**
```bash
# If you have OpenSSL installed:
openssl pkcs12 -export -out certificate.pfx -in certificate.pem -nokeys -password pass:YourPassword123
```

7. Upload the `.pfx` file
8. Enter the password you used
9. Click **Add**

### 6.9 Configure SSL/TLS Binding (if using custom domain)

If you're using the default Azure domain, you can skip this step.

---

## 7. Configure the Application

### 7.1 Navigate to App Service Configuration

1. In Azure Portal, search for "App Services"
2. Click your App Service (e.g., `simplechat-prod-app`)
3. In the left menu, under **Settings**, click **Environment variables**

### 7.2 Add ANF Configuration Variables

Click **+ Add** for each of these:

| Name | Value | Description |
|------|-------|-------------|
| `STORAGE_BACKEND` | `anf` | Switches from Blob to ANF |
| `ANF_OBJECT_API_ENDPOINT` | `https://10.0.2.4:443` | Your endpoint from Step 6.7 |
| `ANF_ACCESS_KEY` | `AKIA...` | Your access key from Step 6.6 |
| `ANF_SECRET_KEY` | `xxxxx...` | Your secret key from Step 6.6 |
| `ANF_VERIFY_SSL` | `true` | Set to `false` only for testing |
| `ANF_USER_DOCUMENTS_BUCKET` | `user-documents` | Bucket name |
| `ANF_GROUP_DOCUMENTS_BUCKET` | `group-documents` | Bucket name |
| `ANF_PUBLIC_DOCUMENTS_BUCKET` | `public-documents` | Bucket name |

### 7.3 Save Configuration

1. Click **Apply** at the bottom
2. Click **Confirm** in the popup
3. The App Service will restart automatically (takes 1-2 minutes)

### 7.4 (Alternative) Keep Using Blob Storage

If you want to deploy ANF infrastructure but continue using Blob Storage for now:

Simply don't add the ANF environment variables, or set:
```
STORAGE_BACKEND=blob
```

You can switch to ANF later by updating the environment variables.

---

## 8. Verify Deployment

### 8.1 Access the Application

1. In Azure Portal, go to your App Service
2. In the **Overview** tab, find **Default domain**
3. Click the URL (e.g., `https://simplechat-prod-app.azurewebsites.net`)

### 8.2 Login

1. You'll be redirected to Microsoft login
2. Sign in with your Azure account
3. Accept permissions if prompted

### 8.3 Test Document Upload

1. In SimpleChat, click **Your Workspace**
2. Click **Upload Document**
3. Select a PDF or text file
4. Click **Upload**
5. Wait for processing to complete

### 8.4 Verify ANF Storage (if configured)

If using ANF, verify the file was uploaded to ANF:

**Option A: Azure Portal**
1. Go to Azure NetApp Files
2. Click your volume
3. Look for the uploaded file in metrics

**Option B: AWS CLI (if installed)**
```bash
aws s3 ls --endpoint-url https://YOUR-ANF-ENDPOINT s3://user-documents/ --no-verify-ssl
```

### 8.5 Test Chat Functionality

1. In SimpleChat, start a new conversation
2. Ask a question about your uploaded document
3. Verify the AI responds with information from the document

---

## 9. Troubleshooting

### 9.1 Deployment Failures

**Error: "The subscription is not registered to use namespace 'Microsoft.NetApp'"**
```bash
az provider register --namespace Microsoft.NetApp
# Wait 5 minutes, then retry deployment
```

**Error: "Insufficient quota"**
- Go to Azure Portal → Subscriptions → Usage + quotas
- Request quota increase for the resource

**Error: "Location not available"**
- Azure NetApp Files isn't available in all regions
- Try: `eastus`, `eastus2`, `westus2`, `westeurope`, `northeurope`

### 9.2 Application Errors

**Error: "ANF storage client not available"**
- Check environment variables are set correctly
- Verify `ANF_OBJECT_API_ENDPOINT` is reachable
- Check `ANF_ACCESS_KEY` and `ANF_SECRET_KEY` are correct

**Error: "SSL certificate verify failed"**
- Ensure certificate is installed on App Service
- Temporarily set `ANF_VERIFY_SSL=false` for testing
- Check certificate hasn't expired

**Error: "Access Denied" when uploading**
- Verify bucket permissions are set to "Read-Write"
- Check credentials haven't expired
- Regenerate access keys if needed

### 9.3 Login Issues

**Error: "AADSTS50011: Reply URL mismatch"**
1. Go to Azure Portal → App registrations → Your app
2. Click **Authentication**
3. Add your App Service URL to **Redirect URIs**:
   - `https://your-app.azurewebsites.net/.auth/login/aad/callback`

### 9.4 View Application Logs

1. In Azure Portal, go to your App Service
2. In the left menu, click **Log stream**
3. Watch real-time logs for errors

Or download logs:
1. Click **Advanced Tools** → **Go**
2. Click **Debug console** → **CMD**
3. Navigate to `LogFiles/Application`

### 9.5 Restart Application

If something isn't working:
1. Go to your App Service
2. Click **Restart** at the top
3. Wait 2 minutes
4. Try again

---

## Quick Reference Commands

### Check Deployment Status
```bash
azd status
```

### View Deployed Resources
```bash
azd show
```

### Redeploy Application Only
```bash
azd deploy
```

### Destroy All Resources
```bash
azd down
```

### View Environment Variables
```bash
azd env get-values
```

---

## Support

- **SimpleChat Issues**: https://github.com/microsoft/simplechat/issues
- **Azure NetApp Files Docs**: https://learn.microsoft.com/en-us/azure/azure-netapp-files/
- **Object REST API Docs**: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure

---

## Appendix A: Azure NetApp Files Regions

ANF is available in these regions (as of 2025):

| Americas | Europe | Asia Pacific |
|----------|--------|--------------|
| East US | North Europe | Australia East |
| East US 2 | West Europe | Southeast Asia |
| West US | UK South | Japan East |
| West US 2 | France Central | Korea Central |
| Central US | Germany West Central | India Central |
| Canada Central | Switzerland North | |

For the latest list: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/?products=netapp

---

## Appendix B: Cost Estimation

| Resource | Estimated Monthly Cost (USD) |
|----------|------------------------------|
| App Service (P1v3) | ~$150 |
| Azure OpenAI | ~$50-500 (usage-based) |
| Cosmos DB | ~$25 |
| AI Search (Basic) | ~$75 |
| Azure NetApp Files (4TB Premium) | ~$500 |
| **Total (with ANF)** | **~$800-1,250/month** |
| **Total (without ANF)** | **~$300-750/month** |

To reduce costs:
- Use Standard tier instead of Premium for ANF
- Use smaller App Service plan for dev/test
- Use consumption-based AI Search

---

## Appendix C: Security Checklist

Before going to production:

- [ ] Enable Azure DDoS Protection
- [ ] Configure Azure Firewall or NSG rules
- [ ] Enable Azure Defender for all resources
- [ ] Rotate ANF access keys every 90 days
- [ ] Enable diagnostic logging for all resources
- [ ] Configure backup for Cosmos DB
- [ ] Set up alerts for quota usage
- [ ] Review and restrict API permissions
- [ ] Enable MFA for all admin accounts
- [ ] Document disaster recovery procedure
