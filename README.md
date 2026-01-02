# Kafka on Azure

[![Validate Kafka deployment](https://github.com/rclevenger-hm/kafka-azure-deployment/actions/workflows/ci.yml/badge.svg)](https://github.com/rclevenger-hm/kafka-azure-deployment/actions/workflows/ci.yml)

Self-managed Apache Kafka 4.3.1 on private Azure virtual machines, with three dedicated KRaft controllers and three or more brokers spread across three availability zones. Terraform provisions infrastructure; a guarded Python bootstrap installs the runtime; operating guides cover acceptance, recovery, upgrades and certificates.

Builds on the [AWS](https://github.com/rclevenger-hm/kafka-aws-deployment), [GCP](https://github.com/rclevenger-hm/kafka-gcp-deployment) and [OCI](https://github.com/rclevenger-hm/kafka-oci-deployment) deployments. The [comparison](docs/parity.md) separates implemented capabilities from live-cloud qualification. This reference implementation has automated source and Kafka tests; an Azure production deployment still requires the [acceptance checks](docs/acceptance.md).

