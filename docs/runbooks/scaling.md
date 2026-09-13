# Broker scaling

## Add capacity

Check disk/network/VM quotas, projected retention and recovery headroom. Increase `broker_count` within 3–18, issue new per-node TLS identities and add their pinned versions. New names/IDs are deterministic. Review the plan for only intended additions; controller count remains three. Complete bootstrap and health checks before assigning partitions.

