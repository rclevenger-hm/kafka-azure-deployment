resource "azurerm_application_security_group" "role" {
  for_each            = toset(["broker", "controller"])
  name                = "${var.name_prefix}-${each.key}"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
