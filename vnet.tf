resource "random_pet" "lb_hostname" {}

resource "azurerm_virtual_network" "vnet" {
  name                = local.names.vnet
  address_space       = local.network.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_network_security_group" "netsg" {
  name                = local.names.nsg
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  dynamic "security_rule" {
    for_each = { for r in local.lb_security_rules : r.name => r }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "netsq" {
  for_each                  = azurerm_subnet.subnet
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.netsg.id
}

resource "azurerm_public_ip" "pubip" {
  name                = local.names.lb_pip
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  domain_name_label   = "${azurerm_resource_group.rg.name}-${random_pet.lb_hostname.id}"
  tags                = local.tags
}

resource "azurerm_lb" "tfalb" {
  name                = local.names.lb
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags
  frontend_ip_configuration {
    name                 = local.names.lb_frontend
    public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = local.names.bepool
  loadbalancer_id = azurerm_lb.tfalb.id
}

resource "azurerm_lb_rule" "tfalbrule" {
  for_each                       = { for r in local.lb_rules : r.name => r }
  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.tfalb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.port
  backend_port                   = each.value.port
  frontend_ip_configuration_name = each.value.fe_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.tfalbprobe.id
}

resource "azurerm_lb_probe" "tfalbprobe" {
  name                = local.names.probe
  loadbalancer_id     = azurerm_lb.tfalb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# resource "azurerm_lb_nat_rule" "ssh" {
#   name                           = "ssh"
#   resource_group_name            = azurerm_resource_group.rg.name
#   loadbalancer_id                = azurerm_lb.tfalb.id
#   protocol                       = "Tcp"
#   frontend_port_start            = 50000
#   frontend_port_end              = 50119
#   backend_port                   = 22
#   frontend_ip_configuration_name = "tfaPublicIP"
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
# }

resource "azurerm_lb_nat_pool" "ssh_pool" {
  name                           = "ssh-pool"
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.tfalb.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = local.names.lb_frontend
}

resource "azurerm_public_ip" "natgwpip" {
  name                = local.names.natgw_pip
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = local.tags
}

resource "azurerm_nat_gateway" "tfanatGW" {
  name                    = local.names.natgw
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags                    = local.tags
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  for_each       = azurerm_subnet.subnet
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.tfanatGW.id
}

resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.tfanatGW.id
  public_ip_address_id = azurerm_public_ip.natgwpip.id
}