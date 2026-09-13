# Rolling runtime changes

## Prepare

Read Apache's version-specific upgrade and downgrade notes; test Kafka/JDK/configuration changes in staging. The renderer accepts Kafka 4.3.x. Update version and SHA512 together. Preserve old binaries and secret versions. Metadata feature upgrades and controller membership changes are separate decisions.

Record health, cluster/node IDs and each node's `/opt/kafka-bootstrap/blob-version.txt`. Apply a reviewed Terraform plan that changes only the intended runtime Blob content. It must not replace VMs or data disks. A manifest upload does not roll a service. Changes to VM custom data, the initial loader, image or shape need the replacement procedure below.

## Roll one node

Run full Kafka health and smoke checks from a private client host. Select one node only, then execute:

```bash
python3 tools/azure_admin.py --resource-group kafka-rg --node kafka-broker-1 refresh --apply-change
```

The helper defaults to printing the exact command; add `--execute` to perform this state-changing operation. Refresh stages a bounded versioned manifest, validates disk/artifacts/TLS, stops the one node and applies its configuration. Check the resulting service, accepted blob version, full ISR and quorum health. Run the smoke test before moving to another node. Roll brokers individually, then nonleader controllers one at a time, then the controller leader. Never stop two controllers together.

## Rollback

Stop on unavailable partitions, growing lag, sustained client failures or missing replicas. Restore desired Terraform inputs and review the resulting manifest-only plan. If the target release permits downgrade and no incompatible feature level was finalized, refresh the affected node using the prior source.

A recorded immutable manifest can be selected with `--version-id RECORDED_VERSION --apply-change`. It still depends on retained Kafka artifacts and its exact Key Vault version. Ensure Blob retention and restore procedures preserve access to historical versions; a deleted/soft-deleted version may need restoration by an authorized storage operator. Reconcile desired Terraform state after a temporary rollback. Manifests cannot undo incompatible data formats or controller membership changes.

## VM replacement

Retain the existing zonal data disk, private IP/DNS, Kafka node ID and cluster ID. Fence and stop the old VM so duplicate identities cannot run. Change only the selected node's lifecycle/replacement configuration in a reviewed maintenance branch; inspect the complete plan to ensure no other node or disk is affected. Deallocate/detach according to Azure's supported procedure, attach the preserved disk at LUN0 to the replacement in the same zone, and restore the destruction guard. Do not remove all guards or use a broad target to conceal dependencies. Practice replacement and attachment sequencing in staging before production patching.
