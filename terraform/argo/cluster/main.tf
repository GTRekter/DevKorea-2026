# ============================================================
# ArgoCD Namespace (for non-primary clusters)
# ============================================================

resource "kubernetes_namespace_v1" "argocd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = "argocd"
  }
}

# ============================================================
# ArgoCD Manager Service Account
# ============================================================

resource "kubernetes_service_account_v1" "argocd_manager" {
  depends_on = [kubernetes_namespace_v1.argocd]

  metadata {
    name      = "argocd-manager"
    namespace = "argocd"
  }
}

# ============================================================
# ArgoCD Manager Cluster Role Binding
# ============================================================

resource "kubernetes_cluster_role_binding_v1" "argocd_manager" {
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
    name      = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    namespace = "argocd"
  }
}

# ============================================================
# ArgoCD Manager Token Secret
# ============================================================

resource "kubernetes_secret_v1" "argocd_manager_token" {
  depends_on = [
    kubernetes_service_account_v1.argocd_manager,
    kubernetes_cluster_role_binding_v1.argocd_manager,
  ]

  metadata {
    name      = "argocd-manager-token"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
