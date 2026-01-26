terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.12.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.38.1"
    }
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = ">= 4.0.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================
# Providers
# ============================================================

provider "ncloud" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  region      = "KR"
  site        = "public"
  support_vpc = true
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}


provider "kubernetes" {
  alias                  = "devkorea_nks_1"
  host                   = module.naver_infrastructure.kube_configs["devkorea-nks-1"].host
  cluster_ca_certificate = base64decode(module.naver_infrastructure.kube_configs["devkorea-nks-1"].cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "ncp-iam-authenticator"
    args        = ["token", "--clusterUuid", module.naver_infrastructure.kube_configs["devkorea-nks-1"].id, "--region", "KR"]
  }
}

# provider "kubernetes" {
#   alias                  = "devkorea_nks_2"
#   host                   = module.naver_infrastructure.kube_configs["devkorea-nks-2"].host
#   cluster_ca_certificate = base64decode(module.naver_infrastructure.kube_configs["devkorea-nks-2"].cluster_ca_certificate)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "ncp-iam-authenticator"
#     args        = ["token", "--clusterUuid", module.naver_infrastructure.kube_configs["devkorea-nks-2"].id, "--region", "KR"]
#   }
# }

provider "kubernetes" {
  alias                  = "devkorea_aks_1"
  host                   = module.azure_infrastructure.kube_configs["devkorea-aks-1"].host
  client_certificate     = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-1"].client_certificate)
  client_key             = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-1"].client_key)
  cluster_ca_certificate = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-1"].cluster_ca_certificate)
}

provider "kubernetes" {
  alias                  = "devkorea_aks_2"
  host                   = module.azure_infrastructure.kube_configs["devkorea-aks-2"].host
  client_certificate     = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-2"].client_certificate)
  client_key             = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-2"].client_key)
  cluster_ca_certificate = base64decode(module.azure_infrastructure.kube_configs["devkorea-aks-2"].cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.naver_infrastructure.kube_configs["devkorea-nks-1"].host
    cluster_ca_certificate = base64decode(module.naver_infrastructure.kube_configs["devkorea-nks-1"].cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "ncp-iam-authenticator"
      args        = ["token", "--clusterUuid", module.naver_infrastructure.kube_configs["devkorea-nks-1"].id, "--region", "KR"]
    }
  }
}

provider "argocd" {
  server_addr = module.argocd_helm.argocd_server_host
  username    = "admin"
  password    = var.argocd_admin_password
  insecure    = true
  grpc_web    = true
}
