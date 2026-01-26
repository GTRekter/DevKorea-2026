# ============================================================
# ArgoCD Projects
# ============================================================

resource "argocd_project" "simple_app" {
  metadata {
    name      = "simple-app"
    namespace = "argocd"
  }

  spec {
    description = "Project for Simple App deployments"

    source_repos = [
      "https://github.com/GTRekter/DevKorea-2026.git",
    ]

    dynamic "destination" {
      for_each = var.cluster_instances
      content {
        server    = var.kube_configs[destination.key].host
        name      = destination.key
        namespace = "simple-app"
      }
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_project" "linkerd_enterprise" {
  metadata {
    name      = "linkerd-enterprise"
    namespace = "argocd"
  }

  spec {
    description = "Project for Linkerd Enterprise deployments"

    orphaned_resources {
      warn = true
    }

    source_repos = [
      "https://helm.buoyant.cloud",
      "https://github.com/GTRekter/DevKorea-2026.git",
    ]

    dynamic "destination" {
      for_each = var.cluster_instances
      content {
        server    = var.kube_configs[destination.key].host
        name      = destination.key
        namespace = "linkerd"
      }
    }

    dynamic "destination" {
      for_each = var.cluster_instances
      content {
        server    = var.kube_configs[destination.key].host
        name      = destination.key
        namespace = "linkerd-multicluster"
      }
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
