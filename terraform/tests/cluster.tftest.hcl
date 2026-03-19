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

run "storage_and_private_services" {
  command = plan
  assert {
    condition     = alltrue([for name, disk in azurerm_managed_disk.data : disk.zone == local.nodes[name].zone && disk.storage_account_type == "PremiumV2_LRS" && disk.network_access_policy == "DenyAll" && !disk.public_network_access_enabled])
    error_message = "Protect zonal data disks and disable disk export."
  }
  assert {
    condition     = alltrue([for disk in azurerm_virtual_machine_data_disk_attachment.data : disk.lun == 0 && disk.caching == "None"])
    error_message = "Use dedicated LUN zero without host caching."
  }
  assert {
    condition     = !azurerm_storage_account.runtime.shared_access_key_enabled && !azurerm_storage_account.runtime.allow_nested_items_to_be_public && azurerm_storage_account.runtime.blob_properties[0].versioning_enabled
    error_message = "Runtime artifacts require Entra access and versioning."
  }
  assert {
    condition     = azurerm_storage_account.runtime.network_rules[0].default_action == "Deny" && length(azurerm_private_endpoint.service) == 2
    error_message = "Limit runtime public endpoint to deployment subnet and provide private runtime/vault endpoints."
  }
  assert {
    condition     = alltrue([for c in azurerm_storage_container.runtime : c.container_access_type == "private"])
    error_message = "Runtime containers must remain private."
  }
}

run "per_node_permissions" {
  command = plan
  assert {
    condition     = alltrue([for name, grant in azurerm_role_assignment.secret : endswith(grant.scope, "/secrets/${var.tls_secrets[name].name}") && grant.role_definition_name == "Key Vault Secrets User"])
    error_message = "Each node may read only its own TLS secret."
  }
  assert {
    condition     = alltrue([for name, grant in azurerm_role_assignment.runtime : endswith(grant.scope, "/containers/${name}") && grant.role_definition_name == "Storage Blob Data Reader"])
    error_message = "Each node may read only its own manifest container."
  }
  assert {
    condition     = alltrue([for name, blob in azurerm_storage_blob.node : endswith(jsondecode(blob.source_content).config.tls_secret_version, var.tls_secrets[name].version)])
    error_message = "Pin every TLS secret version."
  }
  assert {
    condition     = alltrue([for blob in azurerm_storage_blob.node : !strcontains(jsonencode(jsondecode(blob.source_content).config), "-----BEGIN")])
    error_message = "TLS values must stay out of Terraform state."
  }
}

run "explicit_client_and_admin_paths" {
  command = plan
  variables {
    client_cidrs  = ["10.60.0.0/24"]
    admin_cidrs   = ["10.61.0.0/24"]
    metrics_cidrs = ["10.62.0.0/24"]
  }
  assert {
    condition     = azurerm_network_security_rule.client[0].destination_port_range == "9092" && azurerm_network_security_rule.admin[0].destination_port_range == "22" && azurerm_network_security_rule.metrics[0].destination_port_range == "9404"
    error_message = "Keep client, admin and metrics ports separate."
  }
}

run "custom_disk_performance" {
  command = plan
  variables {
    broker_disk_iops       = 6000
    broker_disk_throughput = 250
  }
  assert {
    condition     = azurerm_managed_disk.data["kafka-broker-1"].disk_iops_read_write == 6000 && azurerm_managed_disk.data["kafka-broker-1"].disk_mbps_read_write == 250 && azurerm_managed_disk.data["kafka-controller-1"].disk_iops_read_write == 3000
    error_message = "Broker disk tuning must remain separate from controller disks."
  }
}

run "current_network_flow_logs" {
  command = plan
  assert {
    condition     = azurerm_network_watcher_flow_log.kafka[0].target_resource_id == azurerm_virtual_network.kafka.id && azurerm_network_watcher_flow_log.kafka[0].version == 2
    error_message = "Use VNet flow logs instead of retired NSG flow-log creation."
  }
  assert {
    condition     = length(azurerm_monitor_metric_alert.availability) == 6
    error_message = "Each VM requires an availability alert."
  }
}

run "flow_log_opt_out" {
  command = plan
  variables {
    enable_flow_logs = false
  }
  assert {
    condition     = length(azurerm_network_watcher_flow_log.kafka) == 0 && length(azurerm_storage_account.flow) == 0
    error_message = "Opt out must remove both flow-log resources."
  }
}

run "reject_public_clients" {
  command = plan
  variables {
    client_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.client_cidrs]
}

run "reject_public_metrics" {
  command = plan
  variables {
    metrics_cidrs = ["8.8.8.0/24"]
  }
  expect_failures = [var.metrics_cidrs]
}

run "reject_public_admin" {
  command = plan
  variables {
    admin_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.admin_cidrs]
}

