resource "azurerm_private_dns_zone" "kafka" {
  name                = var.dns_domain
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
