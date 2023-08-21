resource "azurerm_servicebus_namespace" "this" {
  name                = "sbn-${local.func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_servicebus_topic" "this" {
  name         = "topic-${local.func_name}"
  namespace_id = azurerm_servicebus_namespace.this.id

  enable_partitioning = true
}

resource "azurerm_servicebus_subscription" "sum" {
  name               = "topic-sub-${local.func_name}-sum"
  topic_id           = azurerm_servicebus_topic.this.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription" "multiply" {
  name               = "topic-sub-${local.func_name}-multiply"
  topic_id           = azurerm_servicebus_topic.this.id
  max_delivery_count = 1
}