# Architecture

## Placement and identity

Three dedicated controllers and 3–18 brokers span zones 1, 2 and 3. Each node has a static private IP, private DNS name, stable Kafka node ID, user-assigned managed identity and separate zonal data disk. Broker racks use Azure zone identifiers. The default controller IDs are 100–102; broker IDs begin at 1. Cluster and controller directory IDs persist in Terraform state.

Ubuntu 24.04 Gen2 uses a pinned Canonical image version, Trusted Launch, Secure Boot, vTPM, SSH key authentication and x86_64 Dsv5 instances with SCSI disks. NVMe VM families are deliberately rejected: this implementation verifies the SCSI LUN mapping and must not guess at a different device convention.

