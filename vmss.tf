resource "azurerm_orchestrated_virtual_machine_scale_set" "tfa-vmss" {
  name                        = local.names.vmss
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku_name                    = local.vm_size
  instances                   = 2
  platform_fault_domain_count = 1
  zones                       = length(var.vmss_zones) > 0 ? var.vmss_zones : null

  user_data_base64 = base64encode(file("user-data.sh"))

  os_profile {
    linux_configuration {
      disable_password_authentication = true
      admin_username                  = "azureuser"
      admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
      }
    }
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS-gen2"
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "nic"
    primary                       = true
    enable_accelerated_networking = false

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet[var.vmss_subnet_name].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }
  boot_diagnostics {
    storage_account_uri = ""
  }
  lifecycle {
    ignore_changes = [
      instances
    ]
  }
  tags = local.tags
}