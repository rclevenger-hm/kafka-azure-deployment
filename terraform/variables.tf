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
