resource "azurerm_storage_blob" "node" {
  for_each             = local.nodes
  name                 = "runtime.json"
  storage_container_id = azurerm_storage_container.runtime[each.key].id
  type                 = "Block"
  content_type         = "application/json"
  source_content = jsonencode({
    schema_version = 1
    files          = local.runtime_files
    config = {
      node_id             = each.value.id
      node_name           = each.key
      role                = each.value.role
      zone                = each.value.zone
      region              = var.region
      fqdn                = "${each.key}.${var.dns_domain}"
      quorum              = local.quorum
      initial_controllers = local.initial_controllers
      cluster_id          = random_id.cluster.b64_url
      super_users         = local.super_users
      tls_secret_version  = "${data.azurerm_key_vault.tls.vault_uri}secrets/${try(var.tls_secrets[each.key].name, "MISSING")}/${try(var.tls_secrets[each.key].version, "MISSING")}"
      identity_client_id  = azurerm_user_assigned_identity.node[each.key].client_id
      data_disk_id        = azurerm_managed_disk.data[each.key].id
      data_lun            = 0
      kafka_version       = var.kafka_version
      kafka_sha512        = var.kafka_sha512
      retention_hours     = var.retention_hours
    }
  })
  lifecycle {
    precondition {
      condition     = toset(keys(var.tls_secrets)) == toset(keys(local.nodes))
      error_message = "tls_secrets must contain exactly one entry per configured node name."
    }
    precondition {
      condition     = length(distinct([for s in values(var.tls_secrets) : lower(s.name)])) == length(var.tls_secrets)
      error_message = "Each node needs a distinct TLS secret."
    }
  }
  depends_on = [azurerm_role_assignment.deployer_runtime]
}
