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
resource "azurerm_linux_virtual_machine" "node" {
  for_each                        = local.nodes
  name                            = each.key
  computer_name                   = each.key
  location                        = var.region
  resource_group_name             = azurerm_resource_group.kafka.name
  zone                            = each.value.zone
  size                            = each.value.role == "broker" ? var.broker_vm_size : var.controller_vm_size
  admin_username                  = "kafkaadmin"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "kafkaadmin"
    public_key = var.admin_ssh_public_key
  }
  network_interface_ids      = [azurerm_network_interface.node[each.key].id]
  disk_controller_type       = "SCSI"
  secure_boot_enabled        = true
  vtpm_enabled               = true
  provision_vm_agent         = true
  allow_extension_operations = true
  patch_mode                 = "ImageDefault"
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = var.ubuntu_image_version
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 32
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.node[each.key].id]
  }
  boot_diagnostics {}
  custom_data = base64encode(templatefile("${path.module}/../bootstrap/startup.sh", {
    settings = jsonencode({
      blob_url           = "${azurerm_storage_account.runtime.primary_blob_endpoint}${each.key}/runtime.json"
      identity_client_id = azurerm_user_assigned_identity.node[each.key].client_id
    })
    azure_source   = file("${path.module}/../bootstrap/azure.py")
    refresh_source = file("${path.module}/../bootstrap/refresh.py")
  }))
  tags = merge(local.tags, { Role = each.value.role })
  lifecycle { prevent_destroy = true }
  depends_on = [azurerm_storage_blob.node, azurerm_role_assignment.secret, azurerm_role_assignment.runtime, azurerm_private_endpoint.service,
    azurerm_private_dns_zone_virtual_network_link.service, azurerm_private_dns_a_record.node, azurerm_private_dns_zone_virtual_network_link.kafka,
    azurerm_subnet_nat_gateway_association.egress, azurerm_nat_gateway_public_ip_association.egress,
  azurerm_subnet_network_security_group_association.nodes, azurerm_network_interface_application_security_group_association.node, azurerm_network_security_rule.deny_inbound]
}
