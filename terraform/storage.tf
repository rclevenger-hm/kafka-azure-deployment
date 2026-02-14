resource "azurerm_managed_disk" "data" {
  for_each                      = local.nodes
  name                          = "${each.key}-data"
  location                      = var.region
  resource_group_name           = azurerm_resource_group.kafka.name
  storage_account_type          = "PremiumV2_LRS"
  create_option                 = "Empty"
  zone                          = each.value.zone
  disk_size_gb                  = each.value.role == "broker" ? var.broker_disk_gb : var.controller_disk_gb
  disk_iops_read_write          = each.value.role == "broker" ? var.broker_disk_iops : 3000
  disk_mbps_read_write          = each.value.role == "broker" ? var.broker_disk_throughput : 125
  network_access_policy         = "DenyAll"
  public_network_access_enabled = false
  tags                          = merge(local.tags, { Role = each.value.role })
  lifecycle { prevent_destroy = true }
}
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each           = local.nodes
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.node[each.key].id
  lun                = 0
  caching            = "None"
}
resource "random_id" "storage" { byte_length = 5 }
resource "azurerm_storage_account" "runtime" {
  name                            = "kafkaruntime${random_id.storage.hex}"
  resource_group_name             = azurerm_resource_group.kafka.name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access           = "Enabled"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["None"]
    virtual_network_subnet_ids = [var.deployment_subnet_id]
  }
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
  tags = local.tags
  lifecycle { prevent_destroy = true }
}
resource "azurerm_storage_container" "runtime" {
  for_each              = local.nodes
  name                  = each.key
  storage_account_id    = azurerm_storage_account.runtime.id
  container_access_type = "private"
}
