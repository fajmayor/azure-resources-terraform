resource "azurerm_storage_account" "tfa-storage" {
  name                     = "powterraformsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    environment = "pow"
  }
}

resource "azurerm_storage_container" "tfa-storage-container" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfa-storage.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}