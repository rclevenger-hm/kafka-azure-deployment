resource "azurerm_network_interface" "node" {
  for_each                       = local.nodes
  name                           = "${each.key}-nic"
  location                       = var.region
  resource_group_name            = azurerm_resource_group.kafka.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled          = false
  ip_configuration {
    name                          = "private"
    subnet_id                     = azurerm_subnet.nodes[each.value.zone].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.nodes[each.value.zone].address_prefixes[0], each.value.host)
  }
  tags = local.tags
}
resource "azurerm_network_interface_application_security_group_association" "node" {
  for_each                      = local.nodes
  network_interface_id          = azurerm_network_interface.node[each.key].id
  application_security_group_id = azurerm_application_security_group.role[each.value.role].id
}
