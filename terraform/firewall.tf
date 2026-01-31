resource "azurerm_application_security_group" "role" {
  for_each            = toset(["broker", "controller"])
  name                = "${var.name_prefix}-${each.key}"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_network_security_group" "nodes" {
  name                = "${var.name_prefix}-nodes"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_subnet_network_security_group_association" "nodes" {
  for_each                  = local.azs
  subnet_id                 = azurerm_subnet.nodes[each.key].id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

