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

