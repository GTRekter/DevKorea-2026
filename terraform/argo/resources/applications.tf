# ============================================================
# ArgoCD Applications
# ============================================================

resource "argocd_application" "linkerd_enterprise_multicluster" {
  for_each   = var.cluster_instances
  depends_on = [argocd_project.linkerd_enterprise, argocd_application_set.linkerd_enterprise_control_plane, argocd_cluster.clusters]

  metadata {
    name      = "linkerd-enterprise-multicluster-${each.key}"
    namespace = "argocd"
  }

  spec {
    project = "linkerd-enterprise"

    destination {
      server    = var.kube_configs[each.key].host
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
        parameter {
          name  = "controllerDefaults.logLevel"
          value = "debug"
        }

        dynamic "parameter" {
          for_each = { for idx, remote_cluster in var.other_clusters[each.key] : tostring(idx) => remote_cluster }
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

# resource "argocd_application" "linkerd_enterprise_multicluster_credentials" {
#   for_each = merge([
#     for source, remotes in var.other_clusters : {
#       for remote in remotes :
#       "${source}__${remote}" => { source = source, remote = remote }
#     }
#   ]...)

#   depends_on = [argocd_project.linkerd_enterprise, argocd_application.linkerd_enterprise_multicluster]

#   metadata {
#     name      = "linkerd-enterprise-mc-${each.value.source}-creds-${each.value.remote}"
#     namespace = "argocd"
#   }

#   spec {
#     project = "linkerd-enterprise"

#     destination {
#       server    = var.kube_configs[each.value.source].host
#       namespace = "linkerd-multicluster"
#     }

#     source {
#       repo_url        = "https://github.com/GTRekter/DevKorea-2026.git"
#       target_revision = "HEAD"
#       path            = "manifests/${each.value.source}/linkerd"

#       directory {
#         recurse = false
#       }
#     }
#   }
# }
