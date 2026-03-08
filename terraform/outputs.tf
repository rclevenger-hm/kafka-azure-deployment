output "resource_group" { value = azurerm_resource_group.kafka.name }
output "vnet_id" { value = azurerm_virtual_network.kafka.id }
output "bootstrap_servers" { value = join(",", [for name in keys(local.brokers) : "${name}.${var.dns_domain}:9092"]) }
output "controller_quorum" { value = local.quorum }
output "cluster_id" { value = random_id.cluster.b64_url }
output "nodes" {
  value = { for name, node in local.nodes : name => {
    id                 = node.id, role = node.role, zone = node.zone,
    address            = azurerm_network_interface.node[name].private_ip_address,
    fqdn               = "${name}.${var.dns_domain}", vm_id = azurerm_linux_virtual_machine.node[name].id,
    data_disk_id       = azurerm_managed_disk.data[name].id,
    identity_client_id = azurerm_user_assigned_identity.node[name].client_id,
    runtime_url        = "${azurerm_storage_account.runtime.primary_blob_endpoint}${name}/runtime.json"
  } }
}
output "runtime_storage_account" { value = azurerm_storage_account.runtime.name }
output "egress_addresses" { value = { for zone, ip in azurerm_public_ip.nat : zone => ip.ip_address } }
