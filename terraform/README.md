# Terraform module

## Contracts

Terraform >=1.12 and <2, tested with 1.13.5. AzureRM ~>5.8.0 and random ~>3.7 are constrained and locked. Run `terraform init -backend=false -lockfile=readonly`, `terraform validate`, and `terraform test` for credential-free checks. Use `init -reconfigure -backend-config=backend.hcl` for real state. A mock plan does not prove Azure authorization, image availability or quotas.

## Required inputs

| Input | Meaning |
|---|---|
| `subscription_id` | Target Azure subscription |
| `ubuntu_image_version` | Reviewed immutable Canonical Ubuntu 24.04 server image version |
| `admin_ssh_public_key` | Existing operator public key; SSH network ingress remains closed by default |
| `deployment_subnet_id` | Existing management subnet with Microsoft.Storage service endpoint |
| `key_vault_name`, `key_vault_resource_group` | Existing RBAC vault with public access disabled |
| `tls_secrets` | Exact node-name map of distinct secret names and pinned 32-hex versions |

See [example inputs](terraform.tfvars.example) and [deployment prerequisites](../docs/deployment.md). `variables.tf` is the full validation contract. Never place PEM bundles or private keys in Terraform.

## Defaults and optional controls

Region eastus, zones 1/2/3, VNet 10.42.0.0/16, name prefix kafka, private DNS kafka.internal, three D4s_v5 brokers and three D2s_v5 controllers. Broker count supports integer 3–18. Controllers remain exactly three. Dedicated Premium SSD v2 disks default to 500 GiB per broker and 50 GiB per controller; broker IOPS and throughput are configurable within capacity/performance limits. Kafka defaults to pinned 4.3.1 with its SHA512.

Client, metrics and SSH allowlists default empty and accept bounded private IPv4 CIDRs. NSGs explicitly deny unmatched VNet traffic. Flow logs default on and require the existing regional Network Watcher. `action_group_ids` connects VM availability alerts to existing notification groups. Empty groups mean no notification delivery.

## Outputs and lifecycle

Outputs expose the resource group, VNet, bootstrap brokers, controller endpoints, cluster ID, node identities/disks/runtime URLs, runtime account and zonal NAT IPs. There are no secret outputs. Protect state even when outputs are nonsecret.

VMs, managed data disks, runtime account and resource group use `prevent_destroy`. Runtime source/config changes normally update Blob manifests without restarting VMs. Initial loader/image/VM changes may require replacement and must follow a one-node maintenance plan. Do not remove all destruction guards to satisfy a plan.

