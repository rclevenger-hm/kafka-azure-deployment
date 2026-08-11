# Decision: self-managed Kafka on Azure VMs

## Context

The AWS, GCP and OCI references expose node identities, storage, Kafka configuration and operating procedures directly. Comparable Azure behavior needs the same level of control.

## Decision

Use dedicated VM controllers and brokers with Terraform-managed networking, storage and identity. Azure Event Hubs' Kafka endpoint and managed third-party Kafka services are separate alternatives with different operational and feature contracts; they are not substituted for the requested Apache Kafka deployment.

## Consequences

Operators own patching, capacity, certificate lifecycle, quorum recovery and workload qualification. The repository supplies guarded automation and repeatable checks, not a managed-service SLA.
