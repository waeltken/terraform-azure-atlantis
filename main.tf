
locals {
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

  app_settings = {
    "ATLANTIS_GH_APP_ID"             = var.atlantis_github_app_id
    "ATLANTIS_GH_APP_KEY"            = var.atlantis_github_app_key
    "ATLANTIS_GH_APP_WEBHOOK_SECRET" = var.atlantis_github_app_webhook_secret
    "ATLANTIS_GH_USER"               = "foo"
    "ATLANTIS_GH_TOKEN"              = "bar"
    "ATLANTIS_GH_WEBHOOK_SECRET"     = var.atlantis_github_app_webhook_secret
    "ATLANTIS_REPO_WHITELIST"        = join(", ", var.atlantis_repo_allowlist)
    "ATLANTIS_PORT"                  = var.atlantis_port
    "WEBSITES_PORT"                  = var.atlantis_port
    "ATLANTIS_ATLANTIS_URL"          = "https://${var.webapp_name}.azurewebsites.net"
  }
}
