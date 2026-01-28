resource "azurerm_virtual_network" "kafka" {
  name                = "${var.name_prefix}-vnet"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}
resource "azurerm_subnet" "nodes" {
  for_each                        = local.azs
  name                            = "nodes-zone-${each.key}"
  resource_group_name             = azurerm_resource_group.kafka.name
  virtual_network_name            = azurerm_virtual_network.kafka.name
  address_prefixes                = [cidrsubnet(var.vnet_cidr, 3, each.value)]
  default_outbound_access_enabled = false
}
