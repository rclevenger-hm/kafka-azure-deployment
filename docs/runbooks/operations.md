# Daily operations

## Health gate

From an authorized private client host, run `tools/health.py --bootstrap ENDPOINTS --config /secure/client.properties`. Require an elected leader, all three voters, zero quorum follower lag and no unavailable, under-replicated or under-minimum-ISR partitions. Run `tools/smoke.py` for a unique RF3 topic and exact roundtrip. The administrative identity must have topic creation/deletion rights.

## Node inspection

Use `python3 tools/azure_admin.py --resource-group kafka-rg --node kafka-broker-1 status`. The helper invokes a fixed read-only status script through Azure Run Command. Inspect initial bootstrap/Kafka status, mount and disk capacity. Run Command output is limited by Azure; use an authorized private session for deeper journal investigation. Never print secret values or private keys into logs.

For private SSH, configure an existing reachable Bastion/jump path and narrow `admin_cidrs`. No Bastion is provisioned here. A forwarded bootstrap port is insufficient for Kafka clients: every advertised broker address must be routable.

## Application onboarding

Issue a distinct certificate with a unique CN, ensure private DNS/routing, allow its bounded client CIDR and grant only required topic, group and transactional-ID ACLs. Example topic/group grant from an admin host:

```bash
/opt/kafka/bin/kafka-acls.sh --bootstrap-server ENDPOINTS   --command-config /secure/admin.properties --add   --allow-principal 'User:CN=orders-service' --operation Read --operation Describe   --topic orders --group orders-consumers
```

Review ACL semantics for your workload before granting. Test permitted and forbidden operations. Use idempotent producers with `acks=all`; review topic RF, minimum ISR and retention explicitly because broker defaults do not change existing topics.

## Maintenance

Record the source revision, cluster identity, accepted manifest versions and rollback procedure. Require complete health before and after each node. Coordinate upgrades, reassignment and storage work so they do not overlap. Stop on offline partitions, quorum lag, persistent ISR loss or client SLO breach. No helper performs a fleet-wide refresh.
