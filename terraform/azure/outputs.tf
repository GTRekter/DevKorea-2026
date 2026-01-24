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
