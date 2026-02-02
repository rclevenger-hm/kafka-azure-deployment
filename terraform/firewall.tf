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

resource "azurerm_network_security_rule" "quorum" {
  name                                       = "quorum"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9093"
  source_application_security_group_ids      = [for group in azurerm_application_security_group.role : group.id]
  destination_application_security_group_ids = [azurerm_application_security_group.role["controller"].id]
  resource_group_name                        = azurerm_resource_group.kafka.name
  network_security_group_name                = azurerm_network_security_group.nodes.name
}

