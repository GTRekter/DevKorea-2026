# ============================================================
# ArgoCD Application Sets
# ============================================================

# ============================================================
# Simple App ApplicationSet
# ============================================================

resource "argocd_application_set" "simple_app" {
  metadata {
    name      = "simple-app"
    namespace = "argocd"
  }

  spec {
    generator {
      clusters {}
    }

    template {
      metadata {
        name = "simple-app-{{name}}"
      }

      spec {
        project = "default"

        source {
          repo_url        = "https://github.com/GTRekter/DevKorea-2026.git"
          target_revision = "HEAD"
          path            = "manifests"
        }

        destination {
          namespace = "simple-app"
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

# ============================================================
# Linkerd Enterprise ApplicationSets
# ============================================================

resource "argocd_application_set" "linkerd_enterprise_crds" {
  depends_on = [argocd_project.linkerd_enterprise]

  metadata {
    name      = "linkerd-enterprise-crds"
    namespace = "argocd"
  }

  spec {
    generator {
      clusters {}
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
  depends_on = [argocd_project.linkerd_enterprise, argocd_application_set.linkerd_enterprise_crds]

  metadata {
    name      = "linkerd-enterprise-control-plane"
    namespace = "argocd"
  }

  spec {
    generator {
      clusters {}
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
              name  = "controllerLogLevel"
              value = "debug"
            }
            parameter {
              name  = "policyController.logLevel"
              value = "debug"
            }
            parameter {
              name  = "destinationController.logLevel"
              value = "debug"
            }
            parameter {
              name  = "proxy.logLevel"
              value = "debug,linkerd=debug,hickory=error,linkerd_balancer=trace"
            }
            parameter {
              name  = "identityTrustAnchorsPEM"
              value = chomp(var.trust_anchor_cert_pem)
            }
            parameter {
              name  = "identity.issuer.tls.crtPEM"
              value = chomp(var.issuer_cert_pem)
            }
            parameter {
              name  = "identity.issuer.tls.keyPEM"
              value = chomp(var.issuer_private_key_pem)
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
