resource "azurerm_monitor_metric_alert" "availability" {
  for_each            = local.nodes
  name                = "${each.key}-availability"
  resource_group_name = azurerm_resource_group.kafka.name
  scopes              = [azurerm_linux_virtual_machine.node[each.key].id]
  description         = "VM availability fell below healthy; check Kafka quorum before recovery."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }
  dynamic "action" {
    for_each = var.action_group_ids
    content { action_group_id = action.value }
  }
  tags = local.tags
}
resource "azurerm_storage_account" "flow" {
  count                           = var.enable_flow_logs ? 1 : 0
  name                            = "kafkaflow${random_id.storage.hex}"
  resource_group_name             = azurerm_resource_group.kafka.name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access           = "Enabled"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.deployment_subnet_id]
  }
  tags = local.tags
}
resource "azurerm_network_watcher_flow_log" "kafka" {
  count                = var.enable_flow_logs ? 1 : 0
  name                 = "${var.name_prefix}-vnet-flow"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group
  location             = var.region
  target_resource_id   = azurerm_virtual_network.kafka.id
  storage_account_id   = azurerm_storage_account.flow[0].id
  enabled              = true
  version              = 2
  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }
  tags = local.tags
}
