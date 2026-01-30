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
