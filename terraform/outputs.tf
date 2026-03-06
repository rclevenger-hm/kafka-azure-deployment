output "resource_group" { value = azurerm_resource_group.kafka.name }
output "vnet_id" { value = azurerm_virtual_network.kafka.id }
