resource "azurerm_virtual_network" "kafka" {
  name                = "${var.name_prefix}-vnet"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}
