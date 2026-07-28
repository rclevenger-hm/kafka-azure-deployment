# Live acceptance record

Record subscription, region, source SHA, image/Kafka/JDK/provider versions, operator, date and evidence. Mark each gate pass, fail or unverified. These are live Azure gates; repository checks alone do not satisfy them.

## Infrastructure

Confirm three actual zones, VM placement, no node public IPs, explicit NSG denies, Trusted Launch, encrypted disks, data-export restrictions and destruction guards. Verify management-only storage firewall access, private endpoint DNS, Key Vault public networking disabled, exact node role scopes and lack of cross-node secret/container access. Confirm action-group notification delivery and VNet flow-log ingestion.

## Bootstrap and recovery

Verify the pinned image, agent and Python tooling; wait for successful initial bootstrap on all nodes. Check IMDS disk IDs, LUNs, UUID mounts, unprivileged service and cluster/node metadata. Exercise delayed attachment, foreign-disk refusal, unchanged refresh without restart and reboot with preserved data. Record accepted manifest versions and a tested rollback.

## Kafka security and durability

Require a three-voter healthy quorum, expected brokers/racks and complete ISR. Verify mTLS, wrong-hostname/untrusted-client denial and unauthorized topic/group denial. Create RF3 topics with minimum ISR2 and test exact retained records. Verify application certificate/ACL mappings and producer `acks=all` behavior.

