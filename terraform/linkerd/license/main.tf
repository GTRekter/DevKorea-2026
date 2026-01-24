# ============================================================
# Linkerd Namespace
# ============================================================

resource "kubernetes_namespace_v1" "linkerd" {
  metadata {
    name = "linkerd"
  }
}

# ============================================================
# Linkerd License Secret
# ============================================================

resource "kubernetes_secret_v1" "buoyant_license" {
  metadata {
    name      = "buoyant-license"
    namespace = kubernetes_namespace_v1.linkerd.metadata[0].name
  }

  data = {
    license = var.linkerd_enterprise_license
  }

  type = "Opaque"
}
