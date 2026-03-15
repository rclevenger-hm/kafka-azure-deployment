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

