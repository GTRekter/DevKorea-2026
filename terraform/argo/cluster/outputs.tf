# ============================================================
# Cluster Module Outputs
# ============================================================

output "manager_token" {
  description = "The ArgoCD manager service account token"
  value       = kubernetes_secret_v1.argocd_manager_token.data["token"]
  sensitive   = true
}

output "cluster_name" {
  description = "The cluster name"
  value       = var.cluster_name
}
