# Failure exercises

## Rules

Use a disposable or explicitly approved environment. Record baseline health and exact retained test records. Change one failure domain at a time and recover fully between exercises. Establish a stop condition for client errors, offline partitions or unexpected quorum loss. Do not disable TLS, ACLs or identity checks to make a test pass.

## Broker process loss

Stop one broker while retaining its disk. Verify `acks=all` writes continue with two in-sync replicas, alerts show degraded replication and clients rediscover leaders. Restart, wait for full ISR, and verify exact retained and outage-period records. Repeat under measured normal traffic to quantify recovery impact.

## Controller leader loss

Identify the current controller leader, stop only that process and verify another voter is elected. Confirm client metadata/produce/consume continue and the restarted controller rejoins with zero lag. Never deliberately remove two controllers outside a separately approved disaster-recovery exercise.

