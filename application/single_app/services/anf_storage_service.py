# anf_storage_service.py
"""
Azure NetApp Files Storage Service

Provides S3-compatible object storage operations using Azure NetApp Files
Object REST API. This service can be used as an alternative to Azure Blob
Storage for document storage in SimpleChat.

Azure NetApp Files Object REST API is S3-compatible, allowing use of
standard S3 SDKs (boto3) for object operations.

Protocols supported by Azure NetApp Files:
- Object REST API (S3-compatible) - Used by this service
- NFS (NFSv3, NFSv4.1) - For direct file system access
- SMB (2.x, 3.x) - For Windows client access

All protocols access the same underlying data - no duplication.
"""

import os
import logging
from typing import Optional, List, Dict, Any
from io import BytesIO

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError, NoCredentialsError
    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

logger = logging.getLogger(__name__)


class ANFStorageService:
    """
    Service for interacting with Azure NetApp Files Object REST API.

    Uses boto3 S3 client configured for ANF's S3-compatible endpoint.
    Supports both access key and Azure AD (managed identity) authentication.

    Usage:
        service = ANFStorageService()
        service.upload_file('/path/to/file', 'bucket-name', 'object-key')
        content = service.download_file('bucket-name', 'object-key')
    """

    def __init__(
        self,
        endpoint: Optional[str] = None,
        access_key: Optional[str] = None,
        secret_key: Optional[str] = None,
        auth_type: Optional[str] = None
    ):
        """
        Initialize ANF Storage Service.

        Args:
            endpoint: ANF Object REST API endpoint (e.g., https://<account>.blob.netapp.azure.com)
            access_key: S3 access key for authentication
            secret_key: S3 secret key for authentication
            auth_type: Authentication type ('key' or 'managed_identity')

        If parameters are not provided, values are read from environment variables:
            - ANF_OBJECT_API_ENDPOINT
            - ANF_ACCESS_KEY
            - ANF_SECRET_KEY
            - ANF_AUTH_TYPE
        """
        if not BOTO3_AVAILABLE:
            raise ImportError(
                "boto3 is required for ANF storage service. "
                "Install with: pip install boto3"
            )

        self.endpoint = endpoint or os.getenv('ANF_OBJECT_API_ENDPOINT')
        self.auth_type = auth_type or os.getenv('ANF_AUTH_TYPE', 'key')

        if not self.endpoint:
            raise ValueError(
                "ANF Object API endpoint is required. "
                "Set ANF_OBJECT_API_ENDPOINT environment variable or pass endpoint parameter."
            )

        if self.auth_type == 'managed_identity':
            self._setup_with_managed_identity()
        else:
            self.access_key = access_key or os.getenv('ANF_ACCESS_KEY')
            self.secret_key = secret_key or os.getenv('ANF_SECRET_KEY')
            self._setup_with_keys()

        logger.info(f"ANF Storage Service initialized with endpoint: {self.endpoint}")

    def _setup_with_keys(self):
        """Configure S3 client with access key authentication."""
        if not self.access_key or not self.secret_key:
            raise ValueError(
                "ANF access key and secret key are required for key authentication. "
                "Set ANF_ACCESS_KEY and ANF_SECRET_KEY environment variables."
            )

        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=Config(
                signature_version='s3v4',
                s3={'addressing_style': 'path'}
            ),
            region_name='us-east-1'  # Required by boto3, ANF ignores this
        )
        logger.debug("ANF S3 client configured with access key authentication")

    def _setup_with_managed_identity(self):
        """Configure S3 client with Azure AD managed identity authentication."""
        try:
            from azure.identity import DefaultAzureCredential

            # Get Azure AD token and use STS to get S3 credentials
            # Note: This requires ANF to be configured for Azure AD authentication
            credential = DefaultAzureCredential()

            # For now, fall back to key auth if managed identity setup is complex
            # Full implementation would use STS AssumeRoleWithWebIdentity
            logger.warning(
                "Managed identity authentication for ANF Object REST API "
                "requires additional STS configuration. Falling back to key auth."
            )
            self._setup_with_keys()

        except ImportError:
            raise ImportError(
                "azure-identity is required for managed identity authentication. "
                "Install with: pip install azure-identity"
            )

    def upload_file(
        self,
        local_path: str,
        bucket: str,
        key: str,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Upload a file to ANF Object Storage.

        Args:
            local_path: Path to the local file to upload
            bucket: Target bucket name
            key: Object key (path within bucket)
            metadata: Optional metadata dictionary

        Returns:
            Dict containing upload result with ETag

        Raises:
            FileNotFoundError: If local file doesn't exist
            ClientError: If upload fails
        """
        if not os.path.exists(local_path):
            raise FileNotFoundError(f"Local file not found: {local_path}")

        try:
            extra_args = {}
            if metadata:
                extra_args['Metadata'] = metadata

            with open(local_path, 'rb') as f:
                response = self.s3_client.put_object(
                    Bucket=bucket,
                    Key=key,
                    Body=f,
                    **extra_args
                )

            logger.info(f"Uploaded file to ANF: {bucket}/{key}")
            return {
                'bucket': bucket,
                'key': key,
                'etag': response.get('ETag', '').strip('"'),
                'version_id': response.get('VersionId')
            }

        except ClientError as e:
            logger.error(f"Failed to upload file to ANF: {e}")
            raise

    def upload_bytes(
        self,
        data: bytes,
        bucket: str,
        key: str,
        metadata: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Upload bytes data to ANF Object Storage.

        Args:
            data: Bytes data to upload
            bucket: Target bucket name
            key: Object key (path within bucket)
            metadata: Optional metadata dictionary

        Returns:
            Dict containing upload result with ETag
        """
        try:
            extra_args = {}
            if metadata:
                extra_args['Metadata'] = metadata

            response = self.s3_client.put_object(
                Bucket=bucket,
                Key=key,
                Body=data,
                **extra_args
            )

            logger.info(f"Uploaded bytes to ANF: {bucket}/{key}")
            return {
                'bucket': bucket,
                'key': key,
                'etag': response.get('ETag', '').strip('"'),
                'version_id': response.get('VersionId')
            }

        except ClientError as e:
            logger.error(f"Failed to upload bytes to ANF: {e}")
            raise

    def download_file(
        self,
        bucket: str,
        key: str,
        local_path: Optional[str] = None
    ) -> bytes:
        """
        Download a file from ANF Object Storage.

        Args:
            bucket: Source bucket name
            key: Object key to download
            local_path: Optional path to save file locally

        Returns:
            File contents as bytes

        Raises:
            ClientError: If download fails (e.g., object not found)
        """
        try:
            response = self.s3_client.get_object(Bucket=bucket, Key=key)
            data = response['Body'].read()

            if local_path:
                with open(local_path, 'wb') as f:
                    f.write(data)
                logger.info(f"Downloaded file from ANF to: {local_path}")
            else:
                logger.info(f"Downloaded file from ANF: {bucket}/{key}")

            return data

        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchKey':
                logger.error(f"Object not found in ANF: {bucket}/{key}")
            else:
                logger.error(f"Failed to download file from ANF: {e}")
            raise

    def delete_file(self, bucket: str, key: str) -> bool:
        """
        Delete a file from ANF Object Storage.

        Args:
            bucket: Bucket name
            key: Object key to delete

        Returns:
            True if deletion was successful
        """
        try:
            self.s3_client.delete_object(Bucket=bucket, Key=key)
            logger.info(f"Deleted file from ANF: {bucket}/{key}")
            return True

        except ClientError as e:
            logger.error(f"Failed to delete file from ANF: {e}")
            raise

    def list_objects(
        self,
        bucket: str,
        prefix: str = '',
        max_keys: int = 1000
    ) -> List[Dict[str, Any]]:
        """
        List objects in a bucket.

        Args:
            bucket: Bucket name
            prefix: Optional prefix to filter objects
            max_keys: Maximum number of keys to return

        Returns:
            List of object info dictionaries
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
                MaxKeys=max_keys
            )

            objects = []
            for obj in response.get('Contents', []):
                objects.append({
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'],
                    'etag': obj['ETag'].strip('"')
                })

            logger.debug(f"Listed {len(objects)} objects in ANF: {bucket}/{prefix}")
            return objects

        except ClientError as e:
            logger.error(f"Failed to list objects in ANF: {e}")
            raise

    def get_object_metadata(self, bucket: str, key: str) -> Dict[str, Any]:
        """
        Get metadata for an object.

        Args:
            bucket: Bucket name
            key: Object key

        Returns:
            Object metadata dictionary
        """
        try:
            response = self.s3_client.head_object(Bucket=bucket, Key=key)
            return {
                'content_type': response.get('ContentType'),
                'content_length': response.get('ContentLength'),
                'last_modified': response.get('LastModified'),
                'etag': response.get('ETag', '').strip('"'),
                'metadata': response.get('Metadata', {})
            }

        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                logger.error(f"Object not found in ANF: {bucket}/{key}")
            else:
                logger.error(f"Failed to get metadata from ANF: {e}")
            raise

    def list_buckets(self) -> List[str]:
        """
        List all buckets in the ANF volume.

        Returns:
            List of bucket names
        """
        try:
            response = self.s3_client.list_buckets()
            buckets = [b['Name'] for b in response.get('Buckets', [])]
            logger.debug(f"Listed {len(buckets)} buckets in ANF")
            return buckets

        except ClientError as e:
            logger.error(f"Failed to list buckets in ANF: {e}")
            raise

    def create_bucket(self, bucket: str) -> bool:
        """
        Create a new bucket.

        Args:
            bucket: Name for the new bucket

        Returns:
            True if bucket was created successfully
        """
        try:
            self.s3_client.create_bucket(Bucket=bucket)
            logger.info(f"Created bucket in ANF: {bucket}")
            return True

        except ClientError as e:
            if e.response['Error']['Code'] == 'BucketAlreadyExists':
                logger.warning(f"Bucket already exists in ANF: {bucket}")
                return True
            logger.error(f"Failed to create bucket in ANF: {e}")
            raise

    def object_exists(self, bucket: str, key: str) -> bool:
        """
        Check if an object exists.

        Args:
            bucket: Bucket name
            key: Object key

        Returns:
            True if object exists, False otherwise
        """
        try:
            self.s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return False
            raise

    def generate_presigned_url(
        self,
        bucket: str,
        key: str,
        expiration: int = 3600,
        http_method: str = 'GET'
    ) -> str:
        """
        Generate a presigned URL for temporary access.

        Args:
            bucket: Bucket name
            key: Object key
            expiration: URL expiration time in seconds (default 1 hour)
            http_method: HTTP method ('GET' for download, 'PUT' for upload)

        Returns:
            Presigned URL string
        """
        try:
            client_method = 'get_object' if http_method == 'GET' else 'put_object'
            url = self.s3_client.generate_presigned_url(
                ClientMethod=client_method,
                Params={'Bucket': bucket, 'Key': key},
                ExpiresIn=expiration
            )
            logger.debug(f"Generated presigned URL for ANF: {bucket}/{key}")
            return url

        except ClientError as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            raise


def get_anf_storage_service() -> Optional[ANFStorageService]:
    """
    Factory function to get ANF storage service instance.

    Returns:
        ANFStorageService instance if ANF is enabled and configured,
        None otherwise.
    """
    storage_backend = os.getenv('STORAGE_BACKEND', 'blob').lower()

    if storage_backend != 'anf':
        logger.debug("ANF storage not enabled (STORAGE_BACKEND != 'anf')")
        return None

    if not os.getenv('ANF_OBJECT_API_ENDPOINT'):
        logger.warning("ANF storage enabled but ANF_OBJECT_API_ENDPOINT not set")
        return None

    try:
        return ANFStorageService()
    except Exception as e:
        logger.error(f"Failed to initialize ANF storage service: {e}")
        return None
