# anf_storage_plugin.py
"""
Azure NetApp Files Storage Plugin for Semantic Kernel

Provides S3-compatible object storage operations for AI agents using
Azure NetApp Files Object REST API. This plugin mirrors the functionality
of BlobStoragePlugin but uses ANF's S3-compatible API.

Azure NetApp Files supports multiple protocols:
- Object REST API (S3-compatible) - Used by this plugin
- NFS (NFSv3, NFSv4.1) - Direct file system access
- SMB (2.x, 3.x) - Windows client access

All protocols access the same underlying data.
"""

import mimetypes
import base64
from typing import Dict, Any, List

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

from semantic_kernel_plugins.base_plugin import BasePlugin
from semantic_kernel.functions import kernel_function
from semantic_kernel_plugins.plugin_invocation_logger import plugin_function_logger


class ANFStoragePlugin(BasePlugin):
    """
    Semantic Kernel plugin for Azure NetApp Files Object REST API.

    Uses boto3 S3 client to interact with ANF's S3-compatible endpoint.
    Provides the same interface as BlobStoragePlugin for seamless switching.

    Manifest configuration:
        {
            "name": "anf_storage_plugin",
            "type": "anf_storage",
            "endpoint": "https://<account>.blob.netapp.azure.com",
            "auth": {
                "type": "key",
                "access_key": "<access-key>",
                "secret_key": "<secret-key>"
            }
        }
    """

    def __init__(self, manifest: Dict[str, Any]):
        """
        Initialize ANF Storage Plugin.

        Args:
            manifest: Plugin configuration containing endpoint and auth settings
        """
        if not BOTO3_AVAILABLE:
            raise ImportError(
                "boto3 is required for ANF Storage Plugin. "
                "Install with: pip install boto3"
            )

        super().__init__(manifest)
        self.manifest = manifest
        self.endpoint = manifest.get('endpoint')
        self.access_key = manifest.get('auth', {}).get('access_key')
        self.secret_key = manifest.get('auth', {}).get('secret_key')
        self.auth_type = manifest.get('auth', {}).get('type', 'key')
        self._metadata = manifest.get('metadata', {})

        if not self.endpoint:
            raise ValueError(
                "ANFStoragePlugin requires 'endpoint' in the manifest. "
                "Example: https://<account>.blob.netapp.azure.com"
            )

        if self.auth_type == 'key':
            if not self.access_key or not self.secret_key:
                raise ValueError(
                    "ANFStoragePlugin requires 'auth.access_key' and 'auth.secret_key' "
                    "when using key authentication."
                )
            self._setup_with_keys()
        else:
            raise ValueError(
                f"Unsupported auth.type: {self.auth_type}. "
                "Currently only 'key' authentication is supported."
            )

    def _setup_with_keys(self):
        """Configure S3 client with access key authentication."""
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

    @property
    def display_name(self) -> str:
        """Display name for the plugin."""
        return "Azure NetApp Files Storage"

    @property
    def metadata(self) -> Dict[str, Any]:
        """Plugin metadata for discovery and documentation."""
        return {
            "name": self.manifest.get("name", "anf_storage_plugin"),
            "type": "anf_storage",
            "description": self.manifest.get(
                "description",
                "Plugin for Azure NetApp Files Object REST API (S3-compatible) "
                "operations allowing querying of ANF data sources. "
                "Supports NFS, SMB, and S3 API access to the same data."
            ),
            "methods": [
                {
                    "name": "list_buckets",
                    "description": "List all buckets (containers) in the ANF volume.",
                    "parameters": [],
                    "returns": {"type": "List[str]", "description": "List of bucket names."}
                },
                {
                    "name": "list_objects",
                    "description": "List all objects in a given bucket.",
                    "parameters": [
                        {"name": "bucket_name", "type": "str", "description": "Name of the bucket.", "required": True}
                    ],
                    "returns": {"type": "List[str]", "description": "List of object keys."}
                },
                {
                    "name": "get_object_metadata",
                    "description": "Get metadata for a specific object.",
                    "parameters": [
                        {"name": "bucket_name", "type": "str", "description": "Name of the bucket.", "required": True},
                        {"name": "object_key", "type": "str", "description": "Key of the object.", "required": True}
                    ],
                    "returns": {"type": "dict", "description": "Object metadata as a dictionary."}
                },
                {
                    "name": "get_object_content",
                    "description": "Read the contents of an object as text or base64 for images.",
                    "parameters": [
                        {"name": "bucket_name", "type": "str", "description": "Name of the bucket.", "required": True},
                        {"name": "object_key", "type": "str", "description": "Key of the object.", "required": True}
                    ],
                    "returns": {"type": "str", "description": "Object content as a string."}
                },
                {
                    "name": "iterate_objects_in_bucket",
                    "description": "Iterates over all objects in a bucket, reads their data, and returns a dict.",
                    "parameters": [
                        {"name": "bucket_name", "type": "str", "description": "Name of the bucket.", "required": True}
                    ],
                    "returns": {"type": "dict", "description": "Dictionary of object_key: content."}
                }
            ]
        }

    def get_functions(self) -> List[str]:
        """List of available plugin functions."""
        return [
            "list_buckets",
            "list_objects",
            "get_object_metadata",
            "get_object_content",
            "iterate_objects_in_bucket"
        ]

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="List all buckets in the ANF volume.")
    def list_buckets(self) -> List[str]:
        """List all buckets (containers) in the ANF volume."""
        try:
            response = self.s3_client.list_buckets()
            return [b['Name'] for b in response.get('Buckets', [])]
        except ClientError as e:
            return [f"Error listing buckets: {str(e)}"]

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="List all objects in a given bucket.")
    def list_objects(self, bucket_name: str) -> List[str]:
        """List all objects in a given bucket."""
        try:
            response = self.s3_client.list_objects_v2(Bucket=bucket_name)
            return [obj['Key'] for obj in response.get('Contents', [])]
        except ClientError as e:
            return [f"Error listing objects: {str(e)}"]

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Get metadata for a specific object.")
    def get_object_metadata(self, bucket_name: str, object_key: str) -> dict:
        """Get metadata for a specific object."""
        try:
            response = self.s3_client.head_object(Bucket=bucket_name, Key=object_key)
            return {
                'content_type': response.get('ContentType'),
                'content_length': response.get('ContentLength'),
                'last_modified': str(response.get('LastModified')),
                'etag': response.get('ETag', '').strip('"'),
                'metadata': response.get('Metadata', {})
            }
        except ClientError as e:
            return {"error": str(e)}

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Read the contents of an object as text or base64 for images.")
    def get_object_content(self, bucket_name: str, object_key: str) -> str:
        """
        Read the contents of an object as text or base64 for images.

        Args:
            bucket_name: Name of the bucket
            object_key: Key of the object

        Returns:
            Object content as text, base64 (for images), or description (for binary)
        """
        try:
            response = self.s3_client.get_object(Bucket=bucket_name, Key=object_key)
            data = response['Body'].read()

            content_type, _ = mimetypes.guess_type(object_key)

            if content_type and content_type.startswith("text"):
                try:
                    return data.decode('utf-8')
                except UnicodeDecodeError:
                    return "[Unreadable text file]"
            elif content_type and content_type.startswith("image"):
                return base64.b64encode(data).decode('utf-8')
            else:
                return f"[Binary file: {object_key}, type: {content_type or 'unknown'}]"

        except ClientError as e:
            return f"[Error reading object: {str(e)}]"

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Iterates over all objects in a bucket and returns their content.")
    def iterate_objects_in_bucket(self, bucket_name: str) -> dict:
        """
        Iterate over all objects in a bucket and return their content.

        Args:
            bucket_name: Name of the bucket

        Returns:
            Dictionary mapping object keys to their content
        """
        result = {}
        try:
            response = self.s3_client.list_objects_v2(Bucket=bucket_name)

            for obj in response.get('Contents', []):
                object_key = obj['Key']
                try:
                    obj_response = self.s3_client.get_object(
                        Bucket=bucket_name,
                        Key=object_key
                    )
                    data = obj_response['Body'].read()

                    content_type, _ = mimetypes.guess_type(object_key)

                    if content_type and content_type.startswith("text"):
                        try:
                            content = data.decode('utf-8')
                        except UnicodeDecodeError:
                            content = "[Unreadable text file]"
                    elif content_type and content_type.startswith("image"):
                        content = base64.b64encode(data).decode('utf-8')
                    else:
                        content = f"[Binary file: {object_key}, type: {content_type or 'unknown'}]"

                    result[object_key] = content

                except ClientError as e:
                    result[object_key] = f"[Error reading object: {str(e)}]"

        except ClientError as e:
            result['_error'] = f"Error listing objects: {str(e)}"

        return result

    # Compatibility aliases for BlobStoragePlugin interface
    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="List all containers (buckets) - alias for list_buckets.")
    def list_containers(self) -> List[str]:
        """Alias for list_buckets to match BlobStoragePlugin interface."""
        return self.list_buckets()

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="List all blobs (objects) in a container - alias for list_objects.")
    def list_blobs(self, container_name: str) -> List[str]:
        """Alias for list_objects to match BlobStoragePlugin interface."""
        return self.list_objects(container_name)

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Get blob metadata - alias for get_object_metadata.")
    def get_blob_metadata(self, container_name: str, blob_name: str) -> dict:
        """Alias for get_object_metadata to match BlobStoragePlugin interface."""
        return self.get_object_metadata(container_name, blob_name)

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Get blob content - alias for get_object_content.")
    def get_blob_content(self, container_name: str, blob_name: str) -> str:
        """Alias for get_object_content to match BlobStoragePlugin interface."""
        return self.get_object_content(container_name, blob_name)

    @plugin_function_logger("ANFStoragePlugin")
    @kernel_function(description="Iterate blobs in container - alias for iterate_objects_in_bucket.")
    def iterate_blobs_in_container(self, container_name: str) -> dict:
        """Alias for iterate_objects_in_bucket to match BlobStoragePlugin interface."""
        return self.iterate_objects_in_bucket(container_name)
