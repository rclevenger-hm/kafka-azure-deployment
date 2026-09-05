# Daily operations

## Health gate

From an authorized private client host, run `tools/health.py --bootstrap ENDPOINTS --config /secure/client.properties`. Require an elected leader, all three voters, zero quorum follower lag and no unavailable, under-replicated or under-minimum-ISR partitions. Run `tools/smoke.py` for a unique RF3 topic and exact roundtrip. The administrative identity must have topic creation/deletion rights.

## Node inspection

Use `python3 tools/azure_admin.py --resource-group kafka-rg --node kafka-broker-1 status`. The helper invokes a fixed read-only status script through Azure Run Command. Inspect initial bootstrap/Kafka status, mount and disk capacity. Run Command output is limited by Azure; use an authorized private session for deeper journal investigation. Never print secret values or private keys into logs.

For private SSH, configure an existing reachable Bastion/jump path and narrow `admin_cidrs`. No Bastion is provisioned here. A forwarded bootstrap port is insufficient for Kafka clients: every advertised broker address must be routable.

