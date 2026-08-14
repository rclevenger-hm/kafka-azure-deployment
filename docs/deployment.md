# Deploy on Azure

## Prerequisites

Use Terraform 1.13.5, Python 3.12+, OpenSSL and Azure CLI with short-lived credentials. Use Azure public cloud; sovereign-cloud endpoints are not implemented. Choose a region supporting zones 1–3, Dsv5 Trusted Launch VMs, Premium SSD v2 and ZRS storage. Confirm quotas for six VMs, six data disks, three NAT gateways/IPs and two private endpoints.

Pre-register Microsoft.Compute, Microsoft.Network, Microsoft.Storage, Microsoft.KeyVault, Microsoft.ManagedIdentity and Microsoft.Insights in the subscription. Automatic registration is disabled. The deployment principal needs infrastructure management, role-assignment rights at the relevant scopes and private-endpoint approval rights for the existing vault. Keep this privileged identity separate from runtime identities.

Provide an existing private management subnet with the Microsoft.Storage service endpoint enabled. Terraform performs Blob data-plane operations from this subnet. The runtime account allows this subnet through its firewall; ordinary hosted GitHub runners are unsuitable for deployment. Provide an existing RBAC-enabled Key Vault with public access disabled, its management private endpoint/DNS path, and permissions for PKI operators to upload secrets. The module adds a separate vault private endpoint for Kafka nodes.

Network Watcher must already exist in the selected region when flow logs are enabled. Supply its name/resource group. Bring existing Azure Monitor action groups if notifications are required; an alert without actions records state but sends no notification. Client/collector routing, peering and DNS forwarding are separate prerequisites.

## Pin the OS image

List available Canonical Ubuntu 24.04 Gen2 images in your chosen region:

```bash
az vm image list --location eastus --publisher Canonical   --offer ubuntu-24_04-lts --sku server --all --query '[].version' -o tsv
```

Review and test an explicit version, then set `ubuntu_image_version`. `latest` is rejected. Test Python 3, cloud-init, the Azure Linux Agent and the SCSI LUN symlink in a canary. A later image change needs a reviewed one-node replacement.

