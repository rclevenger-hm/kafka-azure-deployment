# Qualification roadmap

## First environment

Complete live provisioning, RBAC propagation, bootstrap, disk/reboot recovery, Run Command, DNS and alert delivery. Record source/version evidence in the acceptance checklist. Resolve environmental quota or policy failures without weakening trust boundaries.

## Reliability

Benchmark realistic load and zone failure. Rehearse certificate/CA rotation, one-node image replacement, manifest rollback and controller membership recovery. Measure RPO/RTO against a tested remote replication/backup strategy.

## Future extensions

Consider destination-filtered egress, automated organizational PKI integration, fleet maintenance coordination and approved additional VM/disk families. Each extension needs failure tests and explicit supported contracts; NVMe and sovereign-cloud support are currently outside scope.
