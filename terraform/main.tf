terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.70.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
  backend "azurerm" {

  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}

locals {
  func_name = "func${random_string.unique.result}"
  loc_for_naming = lower(replace(var.location, " ", ""))
  gh_repo = replace(var.gh_repo, "implodingduck/", "")
  tags = {
    "managed_by" = "terraform"
    "repo"       = local.gh_repo
  }
}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}


data "azurerm_client_config" "current" {}

data "azurerm_log_analytics_workspace" "default" {
  name                = "DefaultWorkspace-${data.azurerm_client_config.current.subscription_id}-EUS"
  resource_group_name = "DefaultResourceGroup-EUS"
} 

data "azurerm_network_security_group" "basic" {
    name                = "basic"
    resource_group_name = "rg-network-eastus"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.gh_repo}-${random_string.unique.result}-${local.loc_for_naming}"
  location = var.location
  tags = local.tags
}


resource "azurerm_application_insights" "app" {
  name                = "${local.func_name}-insights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "other"
  workspace_id        = data.azurerm_log_analytics_workspace.default.id
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.func_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "func" {

  name                       = local.func_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  site_config {
    application_insights_key = azurerm_application_insights.app.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.app.connection_string
    application_stack {
      node_version = "18"
    }
    
  }
  identity {
    type         = "SystemAssigned"
  }
  app_settings = {
    "ENABLE_ORYX_BUILD"               = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"  = "1"
    "WEBSITE_MOUNT_ENABLED"           = "1"
    "EHCONN__fullyQualifiedNamespace" = "${azurerm_eventhub_namespace.this.name}.servicebus.windows.net" 
    "EHNAME"                          = azurerm_eventhub.this.name
    "SBCONN__fullyQualifiedNamespace" = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net" 
    "SBTOPIC"                         = azurerm_servicebus_topic.this.name
    "SBSUB"                           = "topic-sub-${local.func_name}"
    "SANAME"                          = azurerm_storage_account.this.name
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

resource "local_file" "localsettings" {
    content     = <<-EOT
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AzureWebJobsStorage": ""
  }
}
EOT
    filename = "../func/local.settings.json"
}

resource "null_resource" "publish_func" {
  depends_on = [
    azurerm_linux_function_app.func,
    local_file.localsettings
  ]
  triggers = {
    index = "${timestamp()}" #"2023-02-22T19:56:24Z" #"${timestamp()}"
  }
  provisioner "local-exec" {
    working_dir = "../func"
    command     = "npm install && timeout 10m func azure functionapp publish ${azurerm_linux_function_app.func.name}"
    
  }
}

resource "azurerm_role_assignment" "storage" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.func.identity.0.principal_id  
}

resource "azurerm_role_assignment" "eventhub" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = azurerm_linux_function_app.func.identity.0.principal_id  
}

resource "azurerm_role_assignment" "servicebus" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_linux_function_app.func.identity.0.principal_id  
}