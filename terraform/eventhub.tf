resource "azurerm_eventhub_namespace" "this" {
  name                = "ehn-${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  capacity            = 1

  tags = local.tags
}

resource "azurerm_eventhub" "this" {
  name                = "eh-${local.func_name}"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 1
  message_retention   = 1
}