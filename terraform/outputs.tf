output "resource_group" { value = azurerm_resource_group.kafka.name }
output "vnet_id" { value = azurerm_virtual_network.kafka.id }
output "bootstrap_servers" { value = join(",", [for name in keys(local.brokers) : "${name}.${var.dns_domain}:9092"]) }
output "controller_quorum" { value = local.quorum }
output "cluster_id" { value = random_id.cluster.b64_url }
