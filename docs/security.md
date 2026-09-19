# Security model

## Trust boundaries

Deployment operators can change infrastructure, role assignments and executable runtime manifests. Blob write and Azure Run Command permissions are root-equivalent for affected nodes. Separate these from runtime identities and ordinary Kafka application principals. Restrict manual deployment to a protected branch/environment and a trusted private runner.

Each VM selects its own user-assigned identity through IMDS. It receives Storage Blob Data Reader on its own container and Key Vault Secrets User on its own secret. No secret values are read by Terraform. Secret scope includes versions of that secret; the manifest enforces the selected immutable version at retrieval. Compromise of a node exposes that node's readable TLS material, so nodes remain a shared Kafka administrative trust domain.

