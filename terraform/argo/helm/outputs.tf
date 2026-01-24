# ============================================================
# ArgoCD Helm Outputs
# ============================================================

output "helm_release_id" {
  description = "The ID of the ArgoCD helm release"
  value       = helm_release.argocd.id
}

output "argocd_server_host" {
  description = "The ArgoCD server LoadBalancer hostname or IP"
  value       = try(
    data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].hostname,
    data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].ip,
    null
  )
}
