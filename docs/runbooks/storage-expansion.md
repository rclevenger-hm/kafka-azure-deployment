# Expand a managed data disk

## Prepare

Measure retention growth, disk utilization, client p99 and replica recovery headroom. Confirm Premium SSD v2 and VM limits in the selected region. Preserve recovery evidence and require a healthy cluster. Existing disk encryption/export guards must remain intact.

## Increase capacity

Increase the appropriate Terraform size input and inspect the plan for in-place disk updates. Role-level inputs affect all disks of that role; use a reviewed per-node change if a canary is required. Never shrink. Follow Azure's supported expansion/deallocation requirements for the disk and VM configuration; if a stop is necessary, handle one node at a time with full recovery between nodes.

