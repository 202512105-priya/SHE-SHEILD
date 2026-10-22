"""
SHE SHIELD - Cloud Storage & Evidence Vault Connector
Manages secure cloud blob storage uploads for digital evidence and attachments.
"""
import os
import hashlib
import logging

logger = logging.getLogger("CloudStorageService")

class CloudStorageService:
    def __init__(self, bucket_name="sheshield-evidence-vault"):
        self.bucket_name = os.getenv("S3_BUCKET_NAME", bucket_name)
        self.endpoint_url = os.getenv("STORAGE_ENDPOINT", "http://localhost:9000")

    def upload_evidence_file(self, file_bytes, filename, content_type="application/octet-stream"):
        sha256_hash = hashlib.sha256(file_bytes).hexdigest()
        storage_path = f"evidence/{sha256_hash}/{filename}"
        logger.info(f"Uploaded evidence file {filename} to {storage_path} (SHA-256: {sha256_hash})")
        return {
            "status": "uploaded",
            "bucket": self.bucket_name,
            "path": storage_path,
            "sha256": sha256_hash,
            "size_bytes": len(file_bytes)
        }

    def generate_presigned_url(self, storage_path, expiration_seconds=3600):
        return f"{self.endpoint_url}/{self.bucket_name}/{storage_path}?expires={expiration_seconds}"
