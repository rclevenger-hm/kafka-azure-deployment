# Decision: separate runtime and VM lifecycle

## Context

A configuration update must not restart a controller majority or several brokers. VM custom-data/image changes can require replacement.

## Decision

Store desired per-node source/configuration in versioned Blob manifests. Install a small initial loader through custom data and apply changed fingerprints only through explicit one-node refreshes. Leave healthy unchanged fingerprints running. Retain separate destruction guards for VMs and disks.

