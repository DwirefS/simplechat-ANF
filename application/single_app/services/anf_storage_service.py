# anf_storage_service.py
"""
Azure NetApp Files Storage Service - Placeholder

IMPORTANT: Azure NetApp Files Object REST API Setup
==================================================

The Object REST API feature in Azure NetApp Files is currently in PREVIEW
and requires manual configuration through the Azure Portal.

This file serves as documentation for the official setup process.
Application integration will be added once the feature reaches GA
and official SDKs/client libraries are available.

Official Setup Steps (from Microsoft Learn documentation):
---------------------------------------------------------

1. ENROLL IN PREVIEW
   - Submit a waitlist request for the Object REST API feature
   - Activation takes approximately one week
   - You will receive an email confirmation

2. GENERATE SSL CERTIFICATE
   - Create a PEM-formatted SSL certificate in Azure Portal
   - The certificate Subject must be set to the IP/FQDN of your endpoint
   - Format: CN=<IP or FQDN>
   - You are responsible for certificate lifecycle management

3. CREATE A BUCKET
   - Navigate to your NetApp volume in Azure Portal
   - Select "Buckets" from the volume menu
   - Click "+Create" to create a new bucket
   - Specify: bucket name, subdirectory path, UID/GID, permissions

4. GENERATE CREDENTIALS
   - After bucket creation, generate access credentials
   - This creates an access key and secret access key
   - Store credentials securely - they cannot be retrieved again

5. INSTALL CERTIFICATE ON CLIENT
   - Install the certificate on machines that will access the API
   - For Windows: Add to Trusted Root Certification Authorities
   - For Linux: Add to system trust store

6. ACCESS WITH S3-COMPATIBLE CLIENTS
   - Use AWS CLI or S3 Browser (officially documented)
   - When using AWS CLI, use region 'us-east-1'
   - Example: aws s3 ls --endpoint-url https://<endpoint> s3://<bucket>/

Official Documentation:
----------------------
- Configure Object REST API: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure
- Access with S3 Clients: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-browser
- Object REST API Overview: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-introduction

Integration with Azure Services:
-------------------------------
- Azure AI Search: Can index ANF buckets via S3-compatible data source
- Azure Databricks: Connect via Spark with S3A connector
- OneLake: Use shortcuts to virtualize ANF into Microsoft Fabric

Note: This integration is designed to work alongside Azure Blob Storage.
The default storage backend remains Azure Blob Storage (STORAGE_BACKEND="blob").
ANF integration is available when manually configured (STORAGE_BACKEND="anf").
"""

import logging

logger = logging.getLogger(__name__)


class ANFStorageService:
    """
    Placeholder for Azure NetApp Files Object REST API integration.

    The Object REST API is currently in preview and requires manual
    Azure Portal configuration. See module docstring for setup steps.

    Once configured, access the API using:
    - AWS CLI (officially documented by Microsoft)
    - S3 Browser (officially documented by Microsoft)

    Full application integration will be added when:
    1. The feature reaches General Availability (GA)
    2. Official Azure SDKs provide native support
    """

    def __init__(self):
        raise NotImplementedError(
            "Azure NetApp Files Object REST API requires manual configuration. "
            "See https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure "
            "for setup instructions. Once configured, use AWS CLI or S3 Browser to access your buckets."
        )


def get_anf_storage_service():
    """
    Factory function - returns None as ANF requires manual setup.

    The Object REST API feature is in preview and requires:
    1. Waitlist enrollment
    2. SSL certificate generation
    3. Bucket creation via Azure Portal
    4. Credential generation

    See module docstring for complete setup instructions.
    """
    logger.info(
        "ANF Object REST API requires manual Azure Portal configuration. "
        "See documentation: https://learn.microsoft.com/en-us/azure/azure-netapp-files/object-rest-api-access-configure"
    )
    return None
