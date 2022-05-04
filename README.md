# Terraform module which runs Atlantis on Azure AppService

```terraform
module "atlantis" {
  source = "./terraform-azure-atlantis"

  location = "WestEurope"

  atlantis_repo_allowlist = ["github.com/waeltken/*"]
  webapp_name             = "cwatlantis"

  atlantis_github_app_id         = XXXXXXX
  atlantis_github_app_key        = <<-EOT
		-----BEGIN RSA PRIVATE KEY-----
		XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		-----END RSA PRIVATE KEY-----
EOT
  atlantis_github_webhook_secret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}
```
