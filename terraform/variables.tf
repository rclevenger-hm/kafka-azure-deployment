variable "name_prefix" {
  description = "Resource prefix; keep stable after deployment."
  type        = string
  default     = "kafka"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.name_prefix))
    error_message = "Use 3-16 lowercase letters, digits or hyphens."
  }
}


variable "client_cidrs" {
  description = "Explicit IPv4 client network allowlist; closed by default."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for c in var.client_cidrs : can(cidrnetmask(c)) && try(tonumber(split("/", c)[1]) >= 8, false) && can(regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", c)) && try(tonumber(split("/", c)[1]) >= (startswith(c, "10.") ? 8 : startswith(c, "172.") ? 12 : 16), false)])
    error_message = "Clients must use narrowly scoped RFC1918 IPv4 CIDRs."
  }
}


variable "metrics_cidrs" {
  description = "Private collector networks allowed to scrape port 9404."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for c in var.metrics_cidrs : can(cidrnetmask(c)) && try(tonumber(split("/", c)[1]) >= 16, false) && can(regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", c))])
    error_message = "Metrics require private IPv4 CIDRs of /16 or narrower."
  }
}


variable "broker_count" {
  description = "Broker count; adding brokers does not reassign partitions."
  type        = number
  default     = 3
  validation {
    condition     = var.broker_count >= 3 && var.broker_count <= 18 && floor(var.broker_count) == var.broker_count
    error_message = "Use an integer broker count from 3 to 18."
  }
}


variable "dns_domain" {
  description = "Private DNS suffix without trailing dot; dedicated zone."
  type        = string
  default     = "kafka.internal"
  validation {
    condition     = can(regex("^[a-z][a-z0-9.-]*[a-z0-9]$", var.dns_domain)) && strcontains(var.dns_domain, ".")
    error_message = "Use a lowercase DNS domain with no trailing dot."
  }
}


variable "admin_principals" {
  description = "Kafka certificate principals allowed to administer the cluster."
  type        = set(string)
  default     = ["User:CN=kafka-admin"]
  validation {
    condition     = length(var.admin_principals) > 0 && alltrue([for p in var.admin_principals : can(regex("^User:CN=[a-zA-Z0-9._-]+$", p))])
    error_message = "Use explicit simple certificate CN principals."
  }
}


variable "kafka_version" {
  description = "Pinned Kafka 4.3 release used by provisioning."
  type        = string
  default     = "4.3.1"
  validation {
    condition     = can(regex("^4\\.3\\.[0-9]+$", var.kafka_version))
    error_message = "This implementation supports the Kafka 4.3 release line."
  }
}


variable "kafka_sha512" {
  description = "Expected SHA-512 for the exact Kafka tarball."
  type        = string
  default     = "c7d7b2318cb51aa0c61d3246a51c349210073c5c9b754947ef965a439f2f939e8600f204e134a75ac31faf3829c9370960ef7c6a9886c8a1dbf0339a21f4c54c"
  validation {
    condition     = can(regex("^[a-f0-9]{128}$", var.kafka_sha512))
    error_message = "Provide a lowercase SHA-512 digest."
  }
}


variable "retention_hours" {
  description = "Default retention period for newly created topics."
  type        = number
  default     = 168
  validation {
    condition     = var.retention_hours >= 1 && floor(var.retention_hours) == var.retention_hours
    error_message = "Retention must be positive whole hours."
  }
}


variable "subscription_id" {
  type        = string
  description = "Azure public-cloud subscription."
  validation {
    condition     = can(regex("^[a-f0-9-]{36}$", var.subscription_id))
    error_message = "Provide the target subscription UUID."
  }
}
variable "region" {
  type        = string
  default     = "eastus"
  description = "Region supporting three zones, Dsv5 VMs and Premium SSD v2."
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,30}$", var.region))
    error_message = "Use an Azure location identifier such as eastus."
  }
}
variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
  validation {
    condition     = length(var.zones) == 3 && toset(var.zones) == toset(["1", "2", "3"])
    error_message = "Use the three distinct logical availability zones 1, 2 and 3."
  }
}
variable "vnet_cidr" {
  type    = string
  default = "10.42.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vnet_cidr)) && can(regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", var.vnet_cidr)) && try(tonumber(split("/", var.vnet_cidr)[1]) >= 16 && tonumber(split("/", var.vnet_cidr)[1]) <= 20, false)
    error_message = "Use an RFC1918 IPv4 VNet between /16 and /20."
  }
}
variable "ubuntu_image_version" {
  type        = string
  description = "Reviewed Canonical ubuntu-24_04-lts:server image version in region, never latest."
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.ubuntu_image_version))
    error_message = "Pin an explicit Ubuntu image version."
  }
}
variable "admin_ssh_public_key" {
  type        = string
  description = "Existing RSA or Ed25519 public key; private key stays outside Terraform. SSH ingress defaults closed."
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519) [A-Za-z0-9+/]+=*( [^\\r\\n]+)?$", var.admin_ssh_public_key))
    error_message = "Provide a single-line OpenSSH public key."
  }
}
variable "admin_cidrs" {
  type        = set(string)
  default     = []
  description = "Optional private SSH source networks; prefer Azure Run Command or an existing Bastion."
  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrnetmask(c)) && try(tonumber(split("/", c)[1]) >= 24, false) && can(regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", c))])
    error_message = "Admin access requires private IPv4 CIDRs of /24 or narrower."
  }
}
variable "deployment_subnet_id" {
  type        = string
  description = "Existing self-hosted Terraform runner subnet with Microsoft.Storage service endpoint enabled."
  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.deployment_subnet_id))
    error_message = "Provide the existing deployment subnet ARM ID."
  }
}
variable "key_vault_name" {
  type        = string
  description = "Existing RBAC-enabled, public-network-disabled vault containing node TLS JSON secrets."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.key_vault_name))
    error_message = "Use a valid lowercase Key Vault name."
  }
}
variable "key_vault_resource_group" { type = string }
variable "tls_secrets" {
  type        = map(object({ name = string, version = string }))
  description = "Exactly one distinct existing secret per node; immutable version, no secret values."
  validation {
    condition     = alltrue([for s in values(var.tls_secrets) : can(regex("^[A-Za-z0-9-]{1,127}$", s.name)) && can(regex("^[a-f0-9]{32}$", s.version))])
    error_message = "Use a Key Vault secret name and immutable 32-hex version."
  }
}

variable "broker_vm_size" {
  type        = string
  default     = "Standard_D4s_v5"
  description = "SCSI x86_64 Dsv5 profile; review zone quota and disk bandwidth."
  validation {
    condition     = can(regex("^Standard_D(2|4|8|16|32|48|64|96)s_v5$", var.broker_vm_size))
    error_message = "Use a supported Dsv5 SCSI VM size."
  }
}

variable "controller_vm_size" {
  type        = string
  default     = "Standard_D2s_v5"
  description = "SCSI x86_64 Dsv5 profile; review zone quota and disk bandwidth."
  validation {
    condition     = can(regex("^Standard_D(2|4|8|16|32|48|64|96)s_v5$", var.controller_vm_size))
    error_message = "Use a supported Dsv5 SCSI VM size."
  }
}

variable "broker_disk_gb" {
  type        = number
  default     = 500
  description = "Premium SSD v2 broker disk size in GiB."
  validation {
    condition     = var.broker_disk_gb >= 20 && var.broker_disk_gb <= 16384 && floor(var.broker_disk_gb) == var.broker_disk_gb
    error_message = "Invalid broker_disk_gb; use whole values within the documented bounds."
  }
}

