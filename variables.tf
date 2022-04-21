variable "name" {
  description = "Name to use on all resources created (AKS cluster, etc)"
  type        = string
  default     = "atlantis"
}

variable "location" {
  description = "Azure Region to deploy your resources to"
  type        = string
}

variable "aks_version_prefix" {
  type    = string
  default = "1.22"
}

variable "aks_node_count" {
  type    = number
  default = 1
}

variable "aks_node_type" {
  type    = string
  default = "Standard_B2s"
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

# Atlantis
variable "atlantis_image" {
  description = "Docker image to run Atlantis with. If not specified, official Atlantis image will be used"
  type        = string
  default     = ""
}

variable "atlantis_version" {
  description = "Verion of Atlantis to run. If not specified latest will be used"
  type        = string
  default     = "latest"
}

variable "atlantis_port" {
  description = "Local port Atlantis should be running on. Default value is most likely fine."
  type        = number
  default     = 4141
}

variable "atlantis_repo_allowlist" {
  description = "List of allowed repositories Atlantis can be used with"
  type        = list(string)
}

variable "allow_repo_config" {
  description = "When true allows the use of atlantis.yaml config files within the source repos."
  type        = string
  default     = "false"
}

variable "atlantis_log_level" {
  description = "Log level that Atlantis will run with. Accepted values are: <debug|info|warn|error>"
  type        = string
  default     = "debug"
}

variable "atlantis_hide_prev_plan_comments" {
  description = "Enables atlantis server --hide-prev-plan-comments hiding previous plan comments on update"
  type        = string
  default     = "false"
}

# Github
variable "atlantis_github_user" {
  description = "GitHub username that is running the Atlantis command"
  type        = string
  default     = ""
}

variable "atlantis_github_user_token" {
  description = "GitHub token of the user that is running the Atlantis command"
  type        = string
  default     = ""
}

variable "atlantis_github_webhook_secret" {
  description = "GitHub webhook secret of an app that is running the Atlantis command"
  type        = string
  default     = ""
}

# Github App
variable "atlantis_github_app_id" {
  description = "GitHub Application id that is running the Atlantis command"
  type        = string
  default     = ""
}

variable "atlantis_github_app_key" {
  description = "GitHub Application private key of the app that is running the Atlantis command"
  type        = string
  default     = ""
}

variable "atlantis_github_app_webhook_secret" {
  description = "GitHub webhook secret of an app that is running the Atlantis command"
  type        = string
  default     = ""
}

variable "dns_zone_name" {
  type    = string
  default = ""
}

variable "letsencrypt_email" {
  type = string
}
