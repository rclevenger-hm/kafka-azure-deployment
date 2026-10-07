# Failure exercises

## Rules

Use a disposable or explicitly approved environment. Record baseline health and exact retained test records. Change one failure domain at a time and recover fully between exercises. Establish a stop condition for client errors, offline partitions or unexpected quorum loss. Do not disable TLS, ACLs or identity checks to make a test pass.

## Broker process loss

Stop one broker while retaining its disk. Verify `acks=all` writes continue with two in-sync replicas, alerts show degraded replication and clients rediscover leaders. Restart, wait for full ISR, and verify exact retained and outage-period records. Repeat under measured normal traffic to quantify recovery impact.

## Controller leader loss

Identify the current controller leader, stop only that process and verify another voter is elected. Confirm client metadata/produce/consume continue and the restarted controller rejoins with zero lag. Never deliberately remove two controllers outside a separately approved disaster-recovery exercise.

## Host and disk

Reboot one node and confirm UUID mounting precedes Kafka startup without formatting. In a disposable replacement test, delay the expected disk attachment, then restore it and verify bootstrap retries. Present a different disk at the LUN and require refusal without writes. Confirm the old VM is fenced before replacement identity reuse.

## Zone and management paths

Use an approved Azure fault-injection plan to isolate one zone. Verify the remaining controller majority, zone-aware replica placement, client routing, NAT independence and management availability. Restore the zone and verify complete data/ISR/quorum recovery. These cloud behaviors are not established by the loopback integration suite.

## TLS and restoration

Rotate one leaf certificate, test an untrusted certificate and rehearse a dual-CA transition. Verify expired or mismatched material is rejected before stopping a healthy service. Restore the chosen backup/DR system in isolation and measure retained records, offsets and recovery objectives before declaring the plan usable.
