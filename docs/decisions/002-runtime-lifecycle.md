# Decision: separate runtime and VM lifecycle

## Context

A configuration update must not restart a controller majority or several brokers. VM custom-data/image changes can require replacement.

## Decision

Store desired per-node source/configuration in versioned Blob manifests. Install a small initial loader through custom data and apply changed fingerprints only through explicit one-node refreshes. Leave healthy unchanged fingerprints running. Retain separate destruction guards for VMs and disks.

## Consequences

Terraform convergence and Kafka readiness are separate gates. Blob write access is privileged executable-code access. Record accepted Blob/secret versions and test rollback. The local lock prevents competing refreshes on one node but does not coordinate different nodes. Loader/image changes require the guarded replacement procedure.
