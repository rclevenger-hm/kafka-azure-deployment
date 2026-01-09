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


