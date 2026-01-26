# ============================================================
# ArgoCD Helm Release
# ============================================================

resource "helm_release" "argocd" {
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
    },
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_admin_password_bcrypt
    }
  ]
}

# ============================================================
# Wait for ArgoCD to be fully ready
# ============================================================

resource "time_sleep" "wait_for_argocd" {
  depends_on = [helm_release.argocd]

  create_duration = "60s"
}

# ============================================================
# ArgoCD Server Service Data Source
# Collects LoadBalancer IP after helm release is deployed
# ============================================================

data "kubernetes_service_v1" "argocd_server" {
  depends_on = [time_sleep.wait_for_argocd]

  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}
