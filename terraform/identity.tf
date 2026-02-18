data "azurerm_key_vault" "tls" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
  lifecycle {
    postcondition {
      condition     = self.rbac_authorization_enabled && !self.public_network_access_enabled
      error_message = "The existing TLS vault must use Azure RBAC and disable public network access."
    }
  }
}
