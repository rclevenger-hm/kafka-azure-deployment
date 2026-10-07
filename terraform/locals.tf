locals {
  tags = merge(var.tags, { ManagedBy = "terraform", Service = "kafka" })
  azs  = { for i, zone in var.zones : zone => i }
  controllers = { for i in range(3) : "${var.name_prefix}-controller-${i + 1}" => {
    id = 100 + i, role = "controller", zone = var.zones[i], host = 10
  } }
  brokers = { for i in range(var.broker_count) : "${var.name_prefix}-broker-${i + 1}" => {
    id = i + 1, role = "broker", zone = var.zones[i % 3], host = 30 + floor(i / 3)
  } }
  nodes               = merge(local.controllers, local.brokers)
  quorum              = join(",", [for name in keys(local.controllers) : "${name}.${var.dns_domain}:9093"])
  initial_controllers = join(",", [for name, node in local.controllers : "${node.id}@${name}.${var.dns_domain}:9093:${random_id.controller_directory[name].b64_url}"])
  super_users         = join(";", sort(concat(tolist(var.admin_principals), [for name in keys(local.nodes) : "User:CN=${name}"])))
  runtime_files       = { for f in ["provision.py", "kafka.service", "kafka.env", "jmx.yml", "azure.py"] : f => file("${path.module}/../bootstrap/${f}") }
}
resource "random_id" "cluster" { byte_length = 16 }
resource "random_id" "controller_directory" {
  for_each    = local.controllers
  byte_length = 16
}
