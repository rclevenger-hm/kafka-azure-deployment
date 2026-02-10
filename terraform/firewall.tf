resource "azurerm_application_security_group" "role" {
  for_each            = toset(["broker", "controller"])
  name                = "${var.name_prefix}-${each.key}"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_network_security_group" "nodes" {
  name                = "${var.name_prefix}-nodes"
  location            = var.region
  resource_group_name = azurerm_resource_group.kafka.name
  tags                = local.tags
}
resource "azurerm_subnet_network_security_group_association" "nodes" {
  for_each                  = local.azs
  subnet_id                 = azurerm_subnet.nodes[each.key].id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

resource "azurerm_network_security_rule" "quorum" {
  name                                       = "quorum"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9093"
  source_application_security_group_ids      = [for group in azurerm_application_security_group.role : group.id]
  destination_application_security_group_ids = [azurerm_application_security_group.role["controller"].id]
  resource_group_name                        = azurerm_resource_group.kafka.name
  network_security_group_name                = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "replication" {
  name                                       = "replication"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9094"
  source_application_security_group_ids      = [for group in azurerm_application_security_group.role : group.id]
  destination_application_security_group_ids = [azurerm_application_security_group.role["broker"].id]
  resource_group_name                        = azurerm_resource_group.kafka.name
  network_security_group_name                = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "node_health" {
  name                                       = "node-health"
  priority                                   = 120
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9092"
  source_application_security_group_ids      = [for group in azurerm_application_security_group.role : group.id]
  destination_application_security_group_ids = [azurerm_application_security_group.role["broker"].id]
  resource_group_name                        = azurerm_resource_group.kafka.name
  network_security_group_name                = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "client" {
  count                                      = length(var.client_cidrs) > 0 ? 1 : 0
  name                                       = "client"
  priority                                   = 200
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9092"
  source_address_prefixes                    = sort(tolist(var.client_cidrs))
  destination_application_security_group_ids = [azurerm_application_security_group.role["broker"].id]
  resource_group_name                        = azurerm_resource_group.kafka.name
  network_security_group_name                = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "metrics" {
  count                       = length(var.metrics_cidrs) > 0 ? 1 : 0
  name                        = "metrics"
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9404"
  source_address_prefixes     = sort(tolist(var.metrics_cidrs))
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "admin" {
  count                       = length(var.admin_cidrs) > 0 ? 1 : 0
  name                        = "admin"
  priority                    = 220
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = sort(tolist(var.admin_cidrs))
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "deny_inbound" {
  name                        = "deny-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "internal_outbound" {
  name                        = "internal-outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = var.vnet_cidr
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "https_packages" {
  name                        = "https-packages"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "azure_platform" {
  name                        = "azure-platform"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

resource "azurerm_network_security_rule" "dns" {
  name                        = "dns"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzurePlatformDNS"
  resource_group_name         = azurerm_resource_group.kafka.name
  network_security_group_name = azurerm_network_security_group.nodes.name
}

