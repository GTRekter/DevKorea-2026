# ============================================================
# ArgoCD Clusters
# ============================================================

resource "argocd_cluster" "clusters" {
  for_each = var.cluster_instances

  name   = each.key
  server = var.kube_configs[each.key].host

  config {
    bearer_token = var.cluster_tokens[each.key]
    tls_client_config {
      ca_data = base64decode(var.kube_configs[each.key].cluster_ca_certificate)
    }
  }
}
