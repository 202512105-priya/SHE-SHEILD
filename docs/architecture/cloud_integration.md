# Evidence Vault & Cloud Storage Integration

## Security & Forensic Chain of Custody
- All cybercrime evidence attachments (screenshots, audio, documents) are hashed with SHA-256 client-side.
- Evidence files stored in an isolated S3/MinIO bucket `sheshield-evidence-vault`.
- Object retention policy: 90 days default immutable retention.
- Access restricted via short-lived presigned URLs (1-hour expiry).
