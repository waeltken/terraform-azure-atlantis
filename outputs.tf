output "url" {
	value = "https://${azurerm_linux_web_app.atlantis.default_hostname}"
}