# Daily operations

## Health gate

From an authorized private client host, run `tools/health.py --bootstrap ENDPOINTS --config /secure/client.properties`. Require an elected leader, all three voters, zero quorum follower lag and no unavailable, under-replicated or under-minimum-ISR partitions. Run `tools/smoke.py` for a unique RF3 topic and exact roundtrip. The administrative identity must have topic creation/deletion rights.

