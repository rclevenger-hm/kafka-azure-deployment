# Certificate rotation

## Leaf certificate

Issue a certificate with the same exact node CN and advertised DNS SAN, both clientAuth/serverAuth usages and adequate lifetime. Verify the key pair. Upload from the vault's authorized private management path:

```bash
az keyvault secret set --vault-name YOUR_VAULT --name kafka-broker-1   --file /secure/kafka-broker-1.json --encoding utf-8 --query id -o tsv
```

Record the new 32-hex version and change only that node's `tls_secrets` entry. Apply a reviewed manifest-only plan and follow the one-node [rolling procedure](rolling-upgrade.md). Terraform never reads the PEM values. Confirm clients reconnect, peers authenticate and metrics/health recover before another rotation.

## CA rollover

Distribute a trust bundle containing both old and new CAs, one node at a time, then rotate node and client leaves to the new CA. Verify all peers and applications migrated before removing the old CA through a second controlled roll. Keep exact CN/ACL mappings stable unless an explicit authorization migration is planned.

## Expiry or compromise

The bootstrap rejects certificates with less than 24 hours remaining; monitor expiry well before that threshold. If compromised, revoke access and rotate the affected identity immediately through the incident procedure. Do not bypass mTLS or enable allow-everyone authorization to recover. A rollback manifest may reference an expired or disabled secret; validate retained credentials before relying on it.
