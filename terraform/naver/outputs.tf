# ============================================================
# Cluster Outputs
# ============================================================

output "cluster_uuids" {
  description = "Map of cluster names to their UUIDs"
  value = {
    for name, cluster in ncloud_nks_cluster.clusters : name => cluster.uuid
  }
}

output "cluster_names" {
  description = "List of cluster names"
  value       = keys(var.cluster_instances)
}

output "kube_configs" {
  description = "Map of cluster names to their kube configs"
  value = {
    for name, config in data.ncloud_nks_kube_config.kube_config : name => {
      host                   = config.host
      cluster_ca_certificate = config.cluster_ca_certificate
      id                     = config.id
    }
  }
  sensitive = true
}

output "load_balancer_ids" {
  description = "Load balancer IDs for each cluster"
  value = {
    for k, v in ncloud_lb.linkerd_gateway : k => v.id
  }
}

output "load_balancer_ips" {
  description = "Load balancer public IPs for each cluster"
  value = {
    for k, v in ncloud_lb.linkerd_gateway : k => v.ip_list
  }
}
