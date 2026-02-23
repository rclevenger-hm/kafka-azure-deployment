resource "azurerm_private_dns_zone" "kafka" {
  name                = var.dns_domain
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "kafka" {
  name                  = "${var.name_prefix}-link"
  resource_group_name   = azurerm_resource_group.kafka.name
  private_dns_zone_name = azurerm_private_dns_zone.kafka.name
  virtual_network_id    = azurerm_virtual_network.kafka.id
  registration_enabled  = false
}
