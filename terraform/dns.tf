resource "azurerm_private_dns_zone" "kafka" {
  name                = var.dns_domain
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "kafka" {
  name                 = "${var.name_prefix}-link"
  private_dns_zone_id  = azurerm_private_dns_zone.kafka.id
  virtual_network_id   = azurerm_virtual_network.kafka.id
  registration_enabled = false
}
resource "azurerm_private_dns_a_record" "node" {
  for_each            = local.nodes
  name                = each.key
  private_dns_zone_id = azurerm_private_dns_zone.kafka.id
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
  for_each             = azurerm_private_dns_zone.service
  name                 = "${var.name_prefix}-${each.key}"
  private_dns_zone_id  = each.value.id
  virtual_network_id   = azurerm_virtual_network.kafka.id
  registration_enabled = false
}
resource "azurerm_private_endpoint" "service" {
  for_each            = { blob = azurerm_storage_account.runtime.id, vault = data.azurerm_key_vault.tls.id }
  name                = "${var.name_prefix}-${each.key}"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  subnet_id           = azurerm_subnet.endpoints.id
  private_service_connection {
    name                           = "${var.name_prefix}-${each.key}"
    private_connection_resource_id = each.value
    subresource_names              = [each.key]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "service"
    private_dns_zone_ids = [azurerm_private_dns_zone.service[each.key].id]
  }
  tags = local.tags
}
