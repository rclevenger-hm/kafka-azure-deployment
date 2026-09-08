# Recovery

## First actions

Stop overlapping changes. Preserve journals, Azure activity evidence, mounted UUIDs, disk IDs, node IDs, cluster ID and accepted manifest versions. Determine whether this is a process, VM, disk, network, certificate or quorum failure. Never generate a new cluster ID over existing data or delete metadata files as a repair step.

## One broker

Restart the process if identity and disk checks are intact. For VM loss, retain the managed disk and replace the host in the same zone with the same node identity, private DNS and LUN mapping. Fence the old host, follow the replacement runbook, wait for complete ISR and verify retained data before touching another node.

If the disk is irrecoverable, preserve evidence and rebuild replicas from healthy brokers using explicit replacement capacity. Empty replacement storage must belong to the intended node/cluster. `prevent_destroy` requires deliberate code review; do not discard Terraform state or broadly remove guards. With three brokers, permanent loss requires replacement to restore RF3.

## Controllers

One controller can be recovered while two healthy voters maintain quorum. Preserve its metadata disk and directory identity. If a controller must be replaced with new storage, use Kafka's supported dynamic-quorum membership procedure, verify the voter directory ID and catch-up, then remove the retired member. Merely changing Terraform IDs or zone inputs is not a membership migration.

Loss of a controller majority requires a rehearsed Kafka disaster recovery procedure and retained metadata evidence. Do not format a fresh quorum over broker data and assume consistency.

