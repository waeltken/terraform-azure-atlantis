
locals {
  dummy_user = {
    "ATLANTIS_GH_USER"  = "foo"
    "ATLANTIS_GH_TOKEN" = "bar"
  }
  app_settings = {
    "ATLANTIS_GH_APP_ID"         = var.atlantis_github_app_id
    "ATLANTIS_GH_APP_KEY"        = var.atlantis_github_app_key
    "ATLANTIS_GH_WEBHOOK_SECRET" = var.atlantis_github_webhook_secret
    "ATLANTIS_REPO_WHITELIST"    = join(", ", var.atlantis_repo_allowlist)
    "ATLANTIS_PORT"              = var.atlantis_port
    "WEBSITES_PORT"              = var.atlantis_port
    "ATLANTIS_ATLANTIS_URL"      = "https://${var.webapp_name}.azurewebsites.net"
    "ATLANTIS_WRITE_GIT_CREDS"   = var.atlantis_write_git_creds
  }
}

resource "random_string" "unique" {
  length  = 6
  special = false
  number  = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
}

resource "azurerm_service_plan" "atlantis" {
  name                = "atlantis-serviceplan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  os_type  = "Linux"
  sku_name = "S1"
}

resource "azurerm_storage_account" "atlantis" {
  name                = "${var.name}data${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "atlantis" {
  name                 = "${var.name}-data"
  storage_account_name = azurerm_storage_account.atlantis.name
  quota                = var.storage_quota
}

resource "azurerm_linux_web_app" "atlantis" {
  name                = var.webapp_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.atlantis.id
  https_only          = true

  site_config {
    always_on = true

    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.docker_image_tag
    }
  }

  storage_account {
    name         = "atlantis-data"
    account_name = azurerm_storage_account.atlantis.name
    access_key   = azurerm_storage_account.atlantis.primary_access_key
    type         = "AzureFiles"
    mount_path   = "/atlantis-data"
    share_name   = azurerm_storage_share.atlantis.name
  }

  app_settings = var.run_for_install ? merge(local.app_settings, local.dummy_user) : local.app_settings
}
