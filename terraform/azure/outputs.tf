# ============================================================
# Cluster Outputs
# ============================================================

output "cluster_names" {
  description = "List of cluster names"
  value       = keys(var.cluster_instances)
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.resource_group.name
}

output "kube_configs" {
  description = "Map of cluster names to their kube configs"
  value = {
    for name, cluster in azurerm_kubernetes_cluster.kubernetes_clusters : name => {
      host                   = cluster.kube_config[0].host
      client_certificate     = cluster.kube_config[0].client_certificate
      client_key             = cluster.kube_config[0].client_key
      cluster_ca_certificate = cluster.kube_config[0].cluster_ca_certificate
    }
  }
  sensitive = true
}
