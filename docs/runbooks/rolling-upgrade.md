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

