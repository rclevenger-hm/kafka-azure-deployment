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
resource "azurerm_subnet" "endpoints" {
  name                              = "private-endpoints"
  resource_group_name               = azurerm_resource_group.kafka.name
  virtual_network_name              = azurerm_virtual_network.kafka.name
  address_prefixes                  = [cidrsubnet(var.vnet_cidr, 3, 3)]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}
resource "azurerm_public_ip" "nat" {
  for_each            = local.azs
  name                = "${var.name_prefix}-egress-${each.key}"
  resource_group_name = azurerm_resource_group.kafka.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [each.key]
  tags                = local.tags
}
resource "azurerm_nat_gateway" "egress" {
  for_each                = local.azs
  name                    = "${var.name_prefix}-nat-${each.key}"
  resource_group_name     = azurerm_resource_group.kafka.name
  location                = var.region
  sku_name                = "Standard"
  zones                   = [each.key]
  idle_timeout_in_minutes = 10
  tags                    = local.tags
}
resource "azurerm_nat_gateway_public_ip_association" "egress" {
  for_each             = local.azs
  nat_gateway_id       = azurerm_nat_gateway.egress[each.key].id
  public_ip_address_id = azurerm_public_ip.nat[each.key].id
}
