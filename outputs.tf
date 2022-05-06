output "url" {
  value = "https://${azurerm_linux_web_app.atlantis.default_hostname}"
}

output "principal_id" {
  value = azurerm_linux_web_app.atlantis.identity.0.principal_id
}

output "tenant_id" {
  value = azurerm_linux_web_app.atlantis.identity.0.tenant_id
}
