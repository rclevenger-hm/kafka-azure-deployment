# Cloud capability comparison

The comparison inspected OCI `9f2b2b41d36f75a1fe58f040f3f54ddd3d3b02dc`, GCP `82f26306e88fa85b059e2f5300cb5ea48cbbff7f` and AWS `8e64306908db7436a1ee0717892ae64ae2240a7c`. OCI supplies architectural/operational reference material; GCP and AWS include executable infrastructure and Kafka tests. Scope is the checked revisions, not a claim about all future versions.

## Implemented mapping

| Capability | Existing reference | Azure implementation |
|---|---|---|
| Dedicated KRaft quorum | GCP/AWS: three controllers and three+ brokers | Three controllers, 3–18 brokers, three zones |
| Private networking | Private VPCs, NAT, private DNS | VNet, per-zone NAT, explicit default-outbound disable, private DNS |
| Network isolation | Role-scoped firewall/security groups | Broker/controller ASGs plus explicit VNet inbound deny |
| Persistent storage | GCP SSD / AWS encrypted gp3 and identity checks | Separate encrypted Premium SSD v2, IMDS ID + SCSI LUN validation |
| Machine security | Pinned images, unprivileged service | Pinned Ubuntu 24.04, Trusted Launch, vTPM, hardened systemd |
| Workload identity | GCP service accounts / AWS instance profiles | One managed identity per node |
| TLS lifecycle | Per-node pinned secret versions, mTLS | Secret-scoped RBAC, immutable Key Vault versions, SAN/CN/key checks |
| Runtime change safety | AWS versioned per-node S3 manifests | Versioned per-node Blob containers, local lock, explicit one-node refresh |
| No-op provisioning | Guarded AWS refresh | Healthy unchanged fingerprint returns without restart |
| Durability and authorization | RF3/ISR2, no unclean election, TLS and ACLs | Same with Kafka 4.3.1, all listeners use mTLS |
| Administration | GCP administrative tooling / AWS Session Manager | Azure Run Command helper, optional private SSH/Bastion path |
| Observability | Prometheus/Grafana, cloud flow logs/alarms | Same assets plus current VNet flow logs and VM availability alerts |
| Verification | Python, Terraform mock plans, six-process Kafka | Azure REST/disk regressions, mock plans, real TLS/ACL/fault integration |
| Delivery | Infrastructure and operational guides | Manual OIDC plan/apply on a private runner; guarded rollout runbooks |

