# Terraform module which runs Atlantis on Azure AppService

Azure Terraform module for [Atlantis](https://www.runatlantis.io/) Terraform Pull Request Automation.

```terraform
# Example usage as a terraform module
module "atlantis" {
  source = "./terraform-azure-atlantis"

  location = "WestEurope"

  atlantis_repo_allowlist = ["github.com/someorg/*"]
  webapp_name             = "myatlantis"

  # Use this to start with dummy credentials to do the intial install
  # of the GitHub App
  # run_for_install = true

  atlantis_github_app_id         = XXXXXX
  atlantis_github_app_key        = <<-EOT
  		-----BEGIN RSA PRIVATE KEY-----
  		XXXXXXXXXXXXXXXXXXX
		XXXXXXXXXXXXXXXXXXX
		XXXXXXXXXXXXXXXXXXX
  		-----END RSA PRIVATE KEY-----
		EOT
  atlantis_github_webhook_secret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

data "azurerm_subscription" "primary" {
}

# Assign permissions to Atlantis' mananged identity
resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = module.atlantis.principal_id
}
```
