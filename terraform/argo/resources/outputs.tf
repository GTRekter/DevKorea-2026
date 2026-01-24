# ============================================================
# ArgoCD Resources Outputs
# ============================================================

output "cluster_names" {
  description = "List of ArgoCD cluster names registered"
  value       = keys(argocd_cluster.clusters)
}

output "project_name" {
  description = "The name of the linkerd-enterprise project"
  value       = argocd_project.linkerd_enterprise.metadata[0].name
}
