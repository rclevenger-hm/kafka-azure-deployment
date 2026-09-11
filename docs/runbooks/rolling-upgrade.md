# Rolling runtime changes

## Prepare

Read Apache's version-specific upgrade and downgrade notes; test Kafka/JDK/configuration changes in staging. The renderer accepts Kafka 4.3.x. Update version and SHA512 together. Preserve old binaries and secret versions. Metadata feature upgrades and controller membership changes are separate decisions.

Record health, cluster/node IDs and each node's `/opt/kafka-bootstrap/blob-version.txt`. Apply a reviewed Terraform plan that changes only the intended runtime Blob content. It must not replace VMs or data disks. A manifest upload does not roll a service. Changes to VM custom data, the initial loader, image or shape need the replacement procedure below.

