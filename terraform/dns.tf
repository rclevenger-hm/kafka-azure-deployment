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
resource "azurerm_private_dns_a_record" "node" {
  for_each            = local.nodes
  name                = each.key
  zone_name           = azurerm_private_dns_zone.kafka.name
  resource_group_name = azurerm_resource_group.kafka.name
  ttl                 = 60
  records             = [cidrhost(azurerm_subnet.nodes[each.value.zone].address_prefixes[0], each.value.host)]
}
resource "azurerm_private_dns_zone" "service" {
  for_each            = { blob = "privatelink.blob.core.windows.net", vault = "privatelink.vaultcore.azure.net" }
  name                = each.value
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "service" {
  for_each              = azurerm_private_dns_zone.service
  name                  = "${var.name_prefix}-${each.key}"
  resource_group_name   = azurerm_resource_group.kafka.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.kafka.id
  registration_enabled  = false
}
