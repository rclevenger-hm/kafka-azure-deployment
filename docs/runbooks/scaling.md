# Broker scaling

## Add capacity

Check disk/network/VM quotas, projected retention and recovery headroom. Increase `broker_count` within 3–18, issue new per-node TLS identities and add their pinned versions. New names/IDs are deterministic. Review the plan for only intended additions; controller count remains three. Complete bootstrap and health checks before assigning partitions.

## Rebalance

Adding VMs does not redistribute existing Kafka partitions. Generate an explicit rack-aware reassignment plan with bounded throttles. Review spare disk/network capacity and peak client load. Execute with Kafka's reassignment tool and wait for completion, full ISR and acceptable p99 before removing throttles. Retain the reviewed plan and rollback evidence.

