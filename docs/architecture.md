# Architecture

## Placement and identity

Three dedicated controllers and 3–18 brokers span zones 1, 2 and 3. Each node has a static private IP, private DNS name, stable Kafka node ID, user-assigned managed identity and separate zonal data disk. Broker racks use Azure zone identifiers. The default controller IDs are 100–102; broker IDs begin at 1. Cluster and controller directory IDs persist in Terraform state.

Ubuntu 24.04 Gen2 uses a pinned Canonical image version, Trusted Launch, Secure Boot, vTPM, SSH key authentication and x86_64 Dsv5 instances with SCSI disks. NVMe VM families are deliberately rejected: this implementation verifies the SCSI LUN mapping and must not guess at a different device convention.

## Traffic

| Port | Destination | Allowed origin | Protection |
|---|---|---|---|
| 9092 | Brokers | Kafka nodes and explicit private client CIDRs | Mutual TLS and Kafka ACLs |
| 9093 | Controllers | Kafka node application security groups | Mutual TLS |
| 9094 | Brokers | Kafka node application security groups | Mutual TLS |
| 9404 | All nodes | Explicit private collector CIDRs | NSG isolation; HTTP metrics |
| 22 | All nodes | Explicit private admin CIDRs, empty by default | SSH public keys |
| 443 | Blob/Key Vault private endpoints | Private VNet path | Entra identity and scoped RBAC |

An explicit inbound deny overrides Azure's default VNet-wide allow. Outbound rules allow VNet traffic, DNS, time synchronization and HTTP/HTTPS artifact/platform access, then deny other traffic. This is not destination-level application egress filtering. Each zone has its own NAT gateway; private subnets disable implicit default outbound access.

Runtime Blob Storage uses ZRS, versioning, HTTPS and Entra authentication with shared keys disabled. Its firewall allows the existing management subnet through a Microsoft.Storage service endpoint. Nodes resolve the Blob and Key Vault names to private endpoints. The private DNS zones are linked to the Kafka VNet; link or forward DNS separately for clients/management networks.

