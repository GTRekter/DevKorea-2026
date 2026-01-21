# ============================================================
# ArgoCD Helm Release
# ============================================================

resource "helm_release" "argocd" {
  depends_on = [azurerm_kubernetes_cluster.kubernetes_clusters]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.53.0"
  namespace        = "argocd"
  create_namespace = true
  skip_crds        = true
  timeout          = 600
  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    }
  ]
}

# ============================================================
# ArgoCD Clusters
# ============================================================

resource "argocd_cluster" "aks" {
  for_each   = azurerm_kubernetes_cluster.kubernetes_clusters
  depends_on = [helm_release.argocd]

  name   = each.key
  server = each.value.kube_config[0].host
  config {
    tls_client_config {
      ca_data   = base64decode(each.value.kube_config[0].cluster_ca_certificate)
      cert_data = base64decode(each.value.kube_config[0].client_certificate)
      key_data  = base64decode(each.value.kube_config[0].client_key)
    }
  }
}

# ============================================================
# ArgoCD Clusters Service Account 
# ============================================================

resource "kubernetes_namespace_v1" "argocd_namespace_aks_2" {
  provider = kubernetes.devkorea_aks_2

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_service_account_v1" "sevice_account_argocd_manager_aks_1" {
  provider   = kubernetes.devkorea_aks_1
  depends_on = [helm_release.argocd]

  metadata {
    name      = "argocd-manager"
    namespace = "argocd"
  }
}

resource "kubernetes_service_account_v1" "sevice_account_argocd_manager_aks_2" {
  provider   = kubernetes.devkorea_aks_2
  depends_on = [helm_release.argocd, kubernetes_namespace_v1.argocd_namespace_aks_2]

  metadata {
    name      = "argocd-manager"
    namespace = "argocd"
  }
}

# ============================================================
# ArgoCD Clusters Tokens
# ============================================================

resource "kubernetes_secret_v1" "argocd_manager_token_aks_1" {
  provider   = kubernetes.devkorea_aks_1
  depends_on = [kubernetes_service_account_v1.sevice_account_argocd_manager_aks_1]
  metadata {
    name      = "argocd-manager-token"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.sevice_account_argocd_manager_aks_1.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_secret_v1" "argocd_manager_token_aks_2" {
  provider   = kubernetes.devkorea_aks_2
  depends_on = [kubernetes_service_account_v1.sevice_account_argocd_manager_aks_2]
  metadata {
    name      = "argocd-manager-token"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.sevice_account_argocd_manager_aks_2.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# ============================================================
# ArgoCD Clusters Role Bindings
# ============================================================

resource "kubernetes_cluster_role_binding_v1" "argocd_manager_binding_aks_1" {
  provider = kubernetes.devkorea_aks_1

  metadata {
    name = "argocd-manager-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.sevice_account_argocd_manager_aks_1.metadata[0].name
    namespace = "argocd"
  }
}

resource "kubernetes_cluster_role_binding_v1" "argocd_manager_binding_aks_2" {
  provider = kubernetes.devkorea_aks_2

  metadata {
    name = "argocd-manager-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.sevice_account_argocd_manager_aks_2.metadata[0].name
    namespace = "argocd"
  }
}

# ============================================================
# ArgoCD Project
# ============================================================

resource "argocd_project" "linkerd_enterprise" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "linkerd-enterprise"
    namespace = "argocd"
  }
  spec {
    description  = "Project for Linkerd Enterprise deployments"
    source_repos = [
      "https://helm.buoyant.cloud",
      "https://github.com/GTRekter/DevKorea-2026.git",
    ]
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].host
      name      = "devkorea-aks-1"
      namespace = "linkerd"
    }
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].host
      name      = "devkorea-aks-2"
      namespace = "linkerd"
    }
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-1"].kube_config[0].host
      name      = "devkorea-aks-1"
      namespace = "linkerd-multicluster"
    }
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters["devkorea-aks-2"].kube_config[0].host
      name      = "devkorea-aks-2"
      namespace = "linkerd-multicluster"
    }
    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
    role {
      name = "linkerd-admin"
      policies = [
        "p, proj:linkerd-enterprise:linkerd-admin, applications, get, linkerd-enterprise/*, allow",
        "p, proj:linkerd-enterprise:linkerd-admin, applications, sync, linkerd-enterprise/*, allow",
        "p, proj:linkerd-enterprise:linkerd-admin, clusters, get, linkerd-enterprise/*, allow",
        "p, proj:linkerd-enterprise:linkerd-admin, repositories, create, linkerd-enterprise/*, allow",
        "p, proj:linkerd-enterprise:linkerd-admin, repositories, delete, linkerd-enterprise/*, allow",
        "p, proj:linkerd-enterprise:linkerd-admin, repositories, update, linkerd-enterprise/*, allow",
      ]
    }
    sync_window {
      kind         = "allow"
      applications = ["*"]
      clusters     = ["*"]
      namespaces   = ["linkerd", "linkerd-multicluster"]
      duration     = "3600s"
      schedule     = "10 1 * * *"
      manual_sync  = true
    }
  }
}

# ============================================================
# Linkerd License Namespace and Secret
# ============================================================

resource "kubernetes_namespace_v1" "namespace_linkerd_aks_1" {
  provider = kubernetes.devkorea_aks_1

  metadata {
    name = "linkerd"
  }
}

resource "kubernetes_namespace_v1" "namespace_linkerd_aks_2" {
  provider = kubernetes.devkorea_aks_2

  metadata {
    name = "linkerd"
  }
}

resource "kubernetes_secret_v1" "buoyant_license_aks_1" {
  provider = kubernetes.devkorea_aks_1

  metadata {
    name      = "buoyant-license"
    namespace = kubernetes_namespace_v1.namespace_linkerd_aks_1.metadata[0].name
  }
  data = {
    license = var.linkerd_enterprise_license
  }
  type = "Opaque"
}

resource "kubernetes_secret_v1" "buoyant_license_aks_2" {
  provider = kubernetes.devkorea_aks_2

  metadata {
    name      = "buoyant-license"
    namespace = kubernetes_namespace_v1.namespace_linkerd_aks_2.metadata[0].name
  }
  data = {
    license = var.linkerd_enterprise_license
  }
  type = "Opaque"
}


# ============================================================
# ArgoCD Application Sets
# ============================================================

resource "argocd_application_set" "linkerd_enterprise_crds" {
  depends_on = [ helm_release.argocd, argocd_project.linkerd_enterprise,  argocd_project.linkerd_enterprise ]

  metadata {
    name      = "linkerd-enterprise-crds"
    namespace = "argocd"
  }
  spec {
    generator {
      clusters {
        selector {
          match_labels = {
            (local.cluster_selector_label_key) = local.cluster_selector_label_value
          }
        }
      }
    }
    template {
      metadata {
        name = "linkerd-enterprise-crds-{{name}}"
      }
      spec {
        project = "linkerd-enterprise"
        source {
          repo_url        = "https://helm.buoyant.cloud"
          chart           = "linkerd-enterprise-crds"
          target_revision = var.linkerd_enterprise_version
          helm {
            release_name = "linkerd-crds"
            parameter {
              name  = "installGatewayAPI"
              value = "true"
            }
          }
        }
        destination {
          namespace = "linkerd"
          server    = "{{server}}"
        }
        sync_policy {
          automated {
            prune     = true
            self_heal = true
          }
          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}

resource "argocd_application_set" "linkerd_enterprise_control_plane" {
  depends_on = [ helm_release.argocd, argocd_project.linkerd_enterprise, argocd_application_set.linkerd_enterprise_crds ]

  metadata {
    name      = "linkerd-enterprise-control-plane"
    namespace = "argocd"
  }
  spec {
    generator {
      clusters {
        selector {
          match_labels = {
            (local.cluster_selector_label_key) = local.cluster_selector_label_value
          }
        }
      }
    }
    template {
      metadata {
        name = "linkerd-enterprise-control-plane-{{name}}"
      }
      spec {
        project = "linkerd-enterprise"
        source {
          repo_url        = "https://helm.buoyant.cloud"
          chart           = "linkerd-enterprise-control-plane"
          target_revision = var.linkerd_enterprise_version
          helm {
            release_name = "linkerd-control-plane"
            parameter {
              name  = "licenseSecret"
              value = "buoyant-license"
            }
            parameter {
              name  = "identityTrustAnchorsPEM"
              value = chomp(tls_self_signed_cert.trust_anchor.cert_pem)
            }
            parameter {
              name  = "identity.issuer.tls.crtPEM"
              value = chomp(tls_locally_signed_cert.issuer.cert_pem)
            }
            parameter {
              name  = "identity.issuer.tls.keyPEM"
              value = chomp(tls_private_key.issuer.private_key_pem)
            }
          }
        }
        destination {
          namespace = "linkerd"
          server    = "{{server}}"
        }
        sync_policy {
          automated {
            prune     = true
            self_heal = true
          }
          sync_options = ["CreateNamespace=true"]
          retry {
            limit = 10
            backoff {
              duration     = "20s"
              factor       = 2
              max_duration = "5m"
            }
          }
        }
      }
    }
  }
}

# ============================================================
# ArgoCD Application 
# ============================================================

resource "argocd_application" "linkerd_enterprise_multicluster" {
  for_each   = local.cluster_instances
  depends_on = [helm_release.argocd, argocd_project.linkerd_enterprise, argocd_application_set.linkerd_enterprise_control_plane]

  metadata {
    name      = "linkerd-enterprise-multicluster-${each.key}"
    namespace = "argocd"
  }
  spec {
    project = "linkerd-enterprise"
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters[each.key].kube_config[0].host
      namespace = "linkerd-multicluster"
    }
    source {
      repo_url        = "https://helm.buoyant.cloud"
      chart           = "linkerd-enterprise-multicluster"
      target_revision = var.linkerd_enterprise_version
      helm {
        release_name = "linkerd-multicluster"
        parameter {
          name  = "enableNamespaceCreation"
          value = "true"
        }
        parameter {
          name  = "gateway.enabled"
          value = "true"
        }
        dynamic "parameter" {
          # Use sequential indices per cluster to avoid gaps in the controllers array
          for_each = { for idx, remote_cluster in local.other_clusters[each.key] : tostring(idx) => remote_cluster }
          iterator = remote
          content {
            name  = "controllers[${remote.key}].link.ref.name"
            value = remote.value
          }
        }
      }
    }
    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
      sync_options = ["CreateNamespace=true"]
      retry {
        limit = 10
        backoff {
          duration     = "20s"
          factor       = 2
          max_duration = "5m"
        }
      }
    }
  }
}

resource "argocd_application" "linkerd_enterprise_multicluster_credentials" {
  for_each = merge([
    for source, remotes in local.other_clusters : {
      for remote in remotes :
      "${source}__${remote}" => { source = source, remote = remote }
    }
  ]...)
  depends_on = [helm_release.argocd, argocd_project.linkerd_enterprise, argocd_application.linkerd_enterprise_multicluster]

  metadata {
    name      = "linkerd-enterprise-mc-${each.value.source}-creds-${each.value.remote}"
    namespace = "argocd"
  }
  spec {
    project = "linkerd-enterprise"
    destination {
      server    = azurerm_kubernetes_cluster.kubernetes_clusters[each.value.source].kube_config[0].host
      namespace = "linkerd-multicluster"
    }
    source {
      repo_url        = "https://github.com/GTRekter/DevKorea-2026.git"
      target_revision = "HEAD"
      path = "manifests/${each.value.source}"
      directory {
        recurse = false
        # include = "credentials-${each.value.remote}.yaml"
      }
    }
  }
}
