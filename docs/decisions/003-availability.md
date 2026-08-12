# Decision: three zones and explicit network paths

## Context

A Kafka quorum tolerates one voter failure, while RF3/minimum ISR2 requires usable replicas across failure domains. Shared egress or implicit Azure VNet allows can undermine the intended boundaries.

