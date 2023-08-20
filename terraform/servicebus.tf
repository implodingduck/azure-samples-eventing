resource "azurerm_servicebus_namespace" "this" {
  name                = "sbn-${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"

  tags = local.tags
}

resource "azurerm_servicebus_topic" "this" {
  name         = "topic-${local.func_name}"
  namespace_id = azurerm_servicebus_namespace.this.id

  enable_partitioning = true
}