# Security model

## Trust boundaries

Deployment operators can change infrastructure, role assignments and executable runtime manifests. Blob write and Azure Run Command permissions are root-equivalent for affected nodes. Separate these from runtime identities and ordinary Kafka application principals. Restrict manual deployment to a protected branch/environment and a trusted private runner.

Each VM selects its own user-assigned identity through IMDS. It receives Storage Blob Data Reader on its own container and Key Vault Secrets User on its own secret. No secret values are read by Terraform. Secret scope includes versions of that secret; the manifest enforces the selected immutable version at retrieval. Compromise of a node exposes that node's readable TLS material, so nodes remain a shared Kafka administrative trust domain.

## Network and data

Nodes have no public IPs. Broker, controller, client, metrics and optional SSH rules are separate; an explicit deny overrides Azure's broad default VNet inbound rule. Clients and collectors need reviewed private routes/CIDRs. JMX exporter HTTP is private and unauthenticated; NSG isolation is required. Egress permits HTTPS/HTTP downloads and Azure platform access; organizations requiring destination allowlists should add a tested egress firewall design.

OS and data disks use Azure-managed encryption at rest. Disk exports are disabled. Runtime storage uses HTTPS, ZRS, versioning, no anonymous access and no shared-key authentication. Its public endpoint is firewall-limited to the existing deployment subnet with a service endpoint; nodes use Private Link. The TLS vault requires RBAC and disabled public networking. Flow-log delivery uses a separate storage account and Azure-services firewall bypass.

## Runtime protections

Authenticated cloud requests bypass ambient HTTP proxies, reject redirects and bound response sizes. TLS response identity and Blob version are checked. Artifacts are checksum-verified before extraction; archive traversal, links and special files are rejected. The runtime runs as an unprivileged system user with systemd hardening. Private keys and staged manifests use restrictive permissions.

The disk check combines IMDS managed disk ID with the Azure SCSI LUN mapping, then refuses partitions, foreign mounts and unexpected signatures. Kafka metadata must match cluster/node identity. These checks guard mistakes, not a malicious root operator or compromised Azure control plane.

## Certificates and authorization

All Kafka listeners require client certificates and hostname verification. The StandardAuthorizer defaults to deny. Node certificates and configured admin principals are superusers; ordinary clients need narrowly scoped topic/group/transactional-ID ACLs. Use a distinct certificate per application and test both allowed and denied operations. Lab-generated credentials are short-lived and not a production PKI.

Plan leaf and CA rotation before expiry. Certificates must match their private keys, SANs and exact node CNs. Validate both clientAuth/serverAuth usages through organizational issuance and live acceptance. Revocation, CRL/OCSP integration and automated PKI rotation are not configured by this repository.

