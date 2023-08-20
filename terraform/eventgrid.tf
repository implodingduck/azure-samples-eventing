resource "azurerm_eventgrid_system_topic" "this" {
  name                   = "eg-topic-${local.func_name}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  source_arm_resource_id = azurerm_storage_account.this.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "this" {
  name                 = "eg-sub-${local.func_name}"
  system_topic         = azurerm_eventgrid_system_topic.this.name
  resource_group_name  = azurerm_resource_group.rg.name
  eventhub_endpoint_id = azurerm_eventhub.this.id
}