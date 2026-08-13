# Decision: three zones and explicit network paths

## Context

A Kafka quorum tolerates one voter failure, while RF3/minimum ISR2 requires usable replicas across failure domains. Shared egress or implicit Azure VNet allows can undermine the intended boundaries.

## Decision

Distribute three controllers and brokers across three zones, provide one NAT per zone, disable default outbound access and use role-specific ingress followed by explicit deny. Use ZRS for manifests and Private Link for node Blob/Key Vault access. Keep a separate firewall-approved management subnet for Terraform data-plane operations.

