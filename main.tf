provider "azurerm" {
  features {}
}

locals {
  traefik_name      = "traefik"
  cert_manager_name = "cert-manager"
}

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
}

data "azurerm_kubernetes_service_versions" "current" {
  location       = azurerm_resource_group.main.location
  version_prefix = var.aks_version_prefix
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.name

  kubernetes_version = data.azurerm_kubernetes_service_versions.current.latest_version

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_type
  }

  identity {
    type = "SystemAssigned"
  }
}
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  username               = azurerm_kubernetes_cluster.main.kube_config.0.username
  password               = azurerm_kubernetes_cluster.main.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  username               = azurerm_kubernetes_cluster.main.kube_config.0.username
  password               = azurerm_kubernetes_cluster.main.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  load_config_file       = "false"
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    username               = azurerm_kubernetes_cluster.main.kube_config.0.username
    password               = azurerm_kubernetes_cluster.main.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "traefik" {
  name       = local.traefik_name
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "v10.19.4"

  namespace        = local.traefik_name
  create_namespace = true
}

module "cert_manager" {
  source  = "terraform-iaac/cert-manager/kubernetes"
  version = "v2.4.2"

  cluster_issuer_email = var.letsencrypt_email
  solvers = [{
    http01 = {
      ingress = {
        class = local.traefik_name
      }
    }
  }]

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = local.traefik_name
    namespace = helm_release.traefik.namespace
  }
}

data "azurerm_dns_zone" "main" {
  count = var.dns_zone_name != "" ? 1 : 0
  name  = var.dns_zone_name
}

resource "azurerm_dns_a_record" "cluster_ingress_dns_record" {
  count = length(data.azurerm_dns_zone.main)
  name  = var.name

  zone_name           = data.azurerm_dns_zone.main.0.name
  resource_group_name = data.azurerm_dns_zone.main.0.resource_group_name

  ttl     = 300
  records = [data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip]
}

resource "helm_release" "atlantis" {
  name       = var.name
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  version    = "3.19.0"

  timeout = 90

  namespace        = var.name
  create_namespace = true

  # set {
  #   name  = "image.tag"
  #   value = "v0.17.6"
  # }

  set {
    name  = "orgWhitelist"
    value = join(", ", var.atlantis_repo_allowlist)
  }

  set {
    name  = "ingress.host"
    value = length(azurerm_dns_a_record.cluster_ingress_dns_record) > 0 ? trimsuffix(azurerm_dns_a_record.cluster_ingress_dns_record.0.fqdn, ".") : ""
  }

  set {
    name  = "atlantisUrl"
    value = "https://${length(azurerm_dns_a_record.cluster_ingress_dns_record) > 0 ? trimsuffix(azurerm_dns_a_record.cluster_ingress_dns_record.0.fqdn, ".") : ""}"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "traefik"
  }

  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls"
    value = "true"
    type  = "string"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = module.cert_manager.cluster_issuer_name
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "${var.name}-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = length(azurerm_dns_a_record.cluster_ingress_dns_record) > 0 ? trimsuffix(azurerm_dns_a_record.cluster_ingress_dns_record.0.fqdn, ".") : ""
  }

  set {
    name  = "githubApp.id"
    value = var.atlantis_github_app_id
  }

  set {
    name  = "githubApp.key"
    value = var.atlantis_github_app_key
  }

  set {
    name  = "githubApp.secret"
    value = var.atlantis_github_app_webhook_secret
  }

  # set {
  #   name  = "github.user"
  #   value = "fake"
  # }

  # set {
  #   name  = "github.token"
  #   value = "fake"
  # }

  # set {
  #   name  = "github.secret"
  #   value = "fake"
  # }

  depends_on = [
    module.cert_manager
  ]
}
