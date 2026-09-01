# Certificate rotation

## Leaf certificate

Issue a certificate with the same exact node CN and advertised DNS SAN, both clientAuth/serverAuth usages and adequate lifetime. Verify the key pair. Upload from the vault's authorized private management path:

```bash
az keyvault secret set --vault-name YOUR_VAULT --name kafka-broker-1   --file /secure/kafka-broker-1.json --encoding utf-8 --query id -o tsv
```

Record the new 32-hex version and change only that node's `tls_secrets` entry. Apply a reviewed manifest-only plan and follow the one-node [rolling procedure](rolling-upgrade.md). Terraform never reads the PEM values. Confirm clients reconnect, peers authenticate and metrics/health recover before another rotation.

