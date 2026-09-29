# Security policy

Report suspected credential exposure or a vulnerability privately through the repository owner's security contact or GitHub private vulnerability reporting when enabled. Do not include private keys, tokens, full Terraform state, secret values or customer payloads in public issues.

## Scope

The [security guide](docs/security.md) describes workload identities, private network paths, default-deny Kafka authorization and disk/runtime guards. Supported inputs target Azure public cloud, pinned Ubuntu 24.04 x86_64 Dsv5/SCSI and Kafka 4.3.x. Validate changes in an isolated environment before rollout.

## Response

Preserve evidence, restrict the affected identity and revoke/rotate exposed credentials. Rotate affected node/client certificates and trust roots through the controlled runbook. Review runtime Blob writers, Azure Run Command activity, role assignments and Terraform changes because these can alter privileged node code. Upgrade through one-node health gates; do not silently disable authentication or destruction guards to recover.
