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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

provider "kubernetes" {
  alias                  = "devkorea_aks_1"
  host                   = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].cluster_ca_certificate)
}

provider "kubernetes" {
  alias                  = "devkorea_aks_2"
  host                   = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].cluster_ca_certificate)
  }
}

provider "argocd" {
  port_forward_with_namespace = "argocd"
  username                    = "admin"
  password                    = var.argocd_admin_password
  insecure                    = true

  kubernetes {
    host                   = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].cluster_ca_certificate)
  }
}
