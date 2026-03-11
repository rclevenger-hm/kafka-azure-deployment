# Terraform module

## Contracts

Terraform >=1.12 and <2, tested with 1.13.5. AzureRM ~>5.8.0 and random ~>3.7 are constrained and locked. Run `terraform init -backend=false -lockfile=readonly`, `terraform validate`, and `terraform test` for credential-free checks. Use `init -reconfigure -backend-config=backend.hcl` for real state. A mock plan does not prove Azure authorization, image availability or quotas.

