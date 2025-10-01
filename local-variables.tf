locals {
  lb_security_rules = [
    for idx, port in var.lb_allowed_ports : {
      name     = "allow-lb-${port}"
      priority = 100 + idx
      port     = port
    }
  ]
  vm_size = lookup(var.vm_size_map, var.environment, "Standard_B1s")

  tags = {
    environment = var.environment
    project     = var.name_prefix
  }

  names = {
    vnet        = "${var.name_prefix}-vnet"
    nsg         = "${var.name_prefix}-nsg"
    lb          = "${var.name_prefix}-lb"
    lb_pip      = "${var.name_prefix}-lb-pip"
    lb_frontend = "${var.name_prefix}-fe"
    bepool      = "${var.name_prefix}-bepool"
    probe       = "${var.name_prefix}-http-probe"
    natgw       = "${var.name_prefix}-natgw"
    natgw_pip   = "${var.name_prefix}-natgw-pip"
    vmss        = "${var.name_prefix}-vmss"
  }

  network = {
    vnet_address_space = var.vnet_address_space
    subnets            = var.subnets
  }

  lb_rules = [
    for port in var.lb_allowed_ports : {
      name     = "port-${port}"
      port     = port
      protocol = "Tcp"
      fe_name  = local.names.lb_frontend
    }
  ]
}