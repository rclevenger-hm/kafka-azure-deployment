mock_provider "azurerm" {
  override_during = plan
  mock_data "azurerm_client_config" { defaults = { object_id = "00000000-0000-0000-0000-000000000001", tenant_id = "00000000-0000-0000-0000-000000000001", subscription_id = "00000000-0000-0000-0000-000000000001" } }
  mock_data "azurerm_key_vault" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.KeyVault/vaults/kafka-tls", vault_uri = "https://kafka-tls.vault.azure.net/", rbac_authorization_enabled = true, public_network_access_enabled = false } }
  mock_resource "azurerm_resource_group" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka" } }
  mock_resource "azurerm_virtual_network" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/virtualNetworks/kafka" } }
  mock_resource "azurerm_subnet" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/virtualNetworks/kafka/subnets/nodes" } }
  mock_resource "azurerm_network_security_group" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/networkSecurityGroups/nodes" } }
  mock_resource "azurerm_application_security_group" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/applicationSecurityGroups/nodes" } }
  mock_resource "azurerm_public_ip" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/publicIPAddresses/egress", ip_address = "203.0.113.10" } }
  mock_resource "azurerm_nat_gateway" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/natGateways/egress" } }
  mock_resource "azurerm_network_interface" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/networkInterfaces/node" } }
  mock_resource "azurerm_linux_virtual_machine" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Compute/virtualMachines/node" } }
  mock_resource "azurerm_managed_disk" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Compute/disks/data" } }
  mock_resource "azurerm_user_assigned_identity" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.ManagedIdentity/userAssignedIdentities/node", client_id = "00000000-0000-0000-0000-000000000001", principal_id = "00000000-0000-0000-0000-000000000001" } }
  mock_resource "azurerm_storage_account" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Storage/storageAccounts/kafkaruntime123", primary_blob_endpoint = "https://kafkaruntime123.blob.core.windows.net/" } }
  mock_resource "azurerm_storage_container" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Storage/storageAccounts/kafkaruntime123/blobServices/default/containers/kafka-node" } }
  mock_resource "azurerm_private_dns_zone" { defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/privateDnsZones/kafka.internal" } }
}
mock_provider "random" {
  override_during = plan
  mock_resource "random_id" { defaults = { b64_url = "AAAAAAAAAAAAAAAAAAAAAA", hex = "0123456789" } }
}
variables {
  subscription_id          = "00000000-0000-0000-0000-000000000001"
  ubuntu_image_version     = "24.04.202609240"
  admin_ssh_public_key     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMysCxS3k50rb2Of0Pk4XPKoz4zIbdSDw04Tlja8CfGn root@51820b8b5f08"
  deployment_subnet_id     = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Network/virtualNetworks/management/subnets/deployment"
  key_vault_name           = "kafka-tls"
  key_vault_resource_group = "security-rg"
  tls_secrets = {
    kafka-controller-1 = { name = "kafka-controller-1", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
    kafka-controller-2 = { name = "kafka-controller-2", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
    kafka-controller-3 = { name = "kafka-controller-3", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
    kafka-broker-1     = { name = "kafka-broker-1", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
    kafka-broker-2     = { name = "kafka-broker-2", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
    kafka-broker-3     = { name = "kafka-broker-3", version = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  }
}

run "private_topology" {
  command = plan
  assert {
    condition     = length(azurerm_linux_virtual_machine.node) == 6 && length(azurerm_managed_disk.data) == 6
    error_message = "Six separate compute and data disk identities required."
  }
  assert {
    condition     = length(toset([for n in local.controllers : n.zone])) == 3 && length(azurerm_nat_gateway.egress) == 3
    error_message = "Controllers and egress must span three zones."
  }
  assert {
    condition     = alltrue([for nic in azurerm_network_interface.node : nic.ip_configuration[0].public_ip_address_id == null])
    error_message = "Nodes must not have public IP addresses."
  }
  assert {
    condition     = alltrue([for subnet in azurerm_subnet.nodes : !subnet.default_outbound_access_enabled])
    error_message = "Require explicit NAT instead of implicit outbound access."
  }
  assert {
    condition     = length(azurerm_network_security_rule.client) == 0 && length(azurerm_network_security_rule.metrics) == 0 && length(azurerm_network_security_rule.admin) == 0
    error_message = "Ingress allowlists must default closed."
  }
  assert {
    condition     = azurerm_network_security_rule.deny_inbound.access == "Deny" && azurerm_network_security_rule.deny_inbound.priority < 65000
    error_message = "Override Azure default VNet inbound allow."
  }
  assert {
    condition     = alltrue([for vm in azurerm_linux_virtual_machine.node : vm.secure_boot_enabled && vm.vtpm_enabled && vm.disable_password_authentication && vm.disk_controller_type == "SCSI"])
    error_message = "Require Trusted Launch, key authentication and the supported disk controller."
  }
  assert {
    condition     = alltrue([for vm in azurerm_linux_virtual_machine.node : length(base64decode(vm.custom_data)) < 65536])
    error_message = "Custom data must remain within 64 KiB."
  }
  assert {
    condition     = alltrue([for vm in azurerm_linux_virtual_machine.node : vm.source_image_reference[0].version == var.ubuntu_image_version])
    error_message = "Pin the reviewed OS image."
  }
}

