# Expand a managed data disk

## Prepare

Measure retention growth, disk utilization, client p99 and replica recovery headroom. Confirm Premium SSD v2 and VM limits in the selected region. Preserve recovery evidence and require a healthy cluster. Existing disk encryption/export guards must remain intact.

## Increase capacity

Increase the appropriate Terraform size input and inspect the plan for in-place disk updates. Role-level inputs affect all disks of that role; use a reviewed per-node change if a canary is required. Never shrink. Follow Azure's supported expansion/deallocation requirements for the disk and VM configuration; if a stop is necessary, handle one node at a time with full recovery between nodes.

## Grow ext4

After Azure reports the new block size, verify the expected IMDS managed disk ID, LUN0, resolved `/dev/disk/azure/scsi1/lun0` device and mounted UUID. This deployment uses an unpartitioned whole-disk ext4 filesystem. On the confirmed node, run `sudo resize2fs /dev/disk/azure/scsi1/lun0`. Never substitute a guessed `/dev/sdX` from another host.

Confirm `lsblk`, `df -h /var/lib/kafka`, journal/filesystem errors, Kafka health and the roundtrip test. Record before/after capacity. Bootstrap deliberately does not automatically resize an existing filesystem.

