# Kafka on Azure

[![Validate Kafka deployment](https://github.com/rclevenger-hm/kafka-azure-deployment/actions/workflows/ci.yml/badge.svg)](https://github.com/rclevenger-hm/kafka-azure-deployment/actions/workflows/ci.yml)

Self-managed Apache Kafka 4.3.1 on private Azure virtual machines, with three dedicated KRaft controllers and three or more brokers spread across three availability zones. Terraform provisions infrastructure; a guarded Python bootstrap installs the runtime; operating guides cover acceptance, recovery, upgrades and certificates.

Builds on the [AWS](https://github.com/rclevenger-hm/kafka-aws-deployment), [GCP](https://github.com/rclevenger-hm/kafka-gcp-deployment) and [OCI](https://github.com/rclevenger-hm/kafka-oci-deployment) deployments. The [comparison](docs/parity.md) separates implemented capabilities from live-cloud qualification. This reference implementation has automated source and Kafka tests; an Azure production deployment still requires the [acceptance checks](docs/acceptance.md).

## Included

- Private VNet, three zonal NAT gateways, private DNS, explicit network deny rules and private endpoints for Blob Storage and Key Vault.
- Separate encrypted Premium SSD v2 disks, stable identities, managed-disk/LUN verification, filesystem guards and protected compute/storage.
- Per-node user-assigned managed identities, secret-scoped Key Vault access and container-scoped runtime reads.
- Mutual TLS on every Kafka listener, hostname verification, default-deny ACLs, RF3 and minimum ISR2.
- Versioned Blob manifests that separate Terraform changes from explicit one-node runtime refreshes.
- Pinned Kafka/JMX checksums, unprivileged hardened systemd services and a lab certificate generator.
- Health, smoke, capacity and Azure administration tools; Prometheus alerts, a Grafana dashboard, VNet flow logs and VM availability alerts.
- Python regression tests, Terraform mock plans and a real six-process exercise covering TLS, denied ACLs, broker outage writes, retained data and controller leader failover.

