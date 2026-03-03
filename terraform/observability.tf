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
