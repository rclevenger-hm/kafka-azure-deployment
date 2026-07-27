# Live acceptance record

Record subscription, region, source SHA, image/Kafka/JDK/provider versions, operator, date and evidence. Mark each gate pass, fail or unverified. These are live Azure gates; repository checks alone do not satisfy them.

## Infrastructure

Confirm three actual zones, VM placement, no node public IPs, explicit NSG denies, Trusted Launch, encrypted disks, data-export restrictions and destruction guards. Verify management-only storage firewall access, private endpoint DNS, Key Vault public networking disabled, exact node role scopes and lack of cross-node secret/container access. Confirm action-group notification delivery and VNet flow-log ingestion.

