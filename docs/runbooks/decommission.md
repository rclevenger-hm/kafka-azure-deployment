# Decommission

## Confirm scope

Stop writes and migrate applications/consumers. Complete required exports, retention and a tested recovery record. Identify the exact subscription, resource group, region, state key and cluster UUID. Inventory secrets, snapshots, private DNS, client routes, monitoring and external dependencies.

## Review guards

VMs, data disks, the runtime account and resource group have separate `prevent_destroy` guards. Remove only intended guards in a reviewed retirement change. AzureRM also refuses resource-group deletion while untracked resources remain. Inventory resources rather than disabling this check to force a destroy. Historical Blob versions, soft-deleted containers and state backups require explicit retention decisions.

## Retire and verify

Review the saved destroy plan before execution, preserve evidence and confirm no unrelated shared resource is included. The existing Key Vault, management network, state account and Network Watcher are not owned by this module. Revoke obsolete role grants, retire node secret versions under the PKI policy and remove external routes/collector targets. Verify billing inventory and retained recovery access after deletion.
