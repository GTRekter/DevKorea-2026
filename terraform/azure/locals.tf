locals {
  # ============================================================
  # Project and Cluster Definitions
  # ============================================================

  project_suffix = "devkorea"
  cluster_instances = {
    "${local.project_suffix}-aks-1" = 0
    "${local.project_suffix}-aks-2" = 1
  }
  cluster_keys                 = keys(local.cluster_instances)
  cluster_selector_label_key   = "argocd.argoproj.io/secret-type"
  cluster_selector_label_value = "cluster"

  # ============================================================
  # Network Configuration Bases
  # ============================================================

  pod_cidr_base     = "10.240.0.0/12"
  service_cidr_base = "10.16.0.0/12"
  vnet_cidr_base    = "10.0.0.0/8"
  vnet_peering_pairs = flatten([
    for source in local.cluster_keys : [
      for target in local.cluster_keys : {
        source = source
        target = target
      } if source != target
    ]
  ])

  # ============================================================
  # Multicluster Configuration
  # ============================================================
  
  other_clusters = {
    for cluster_name in local.cluster_keys : cluster_name => [
      for remote_cluster_name in local.cluster_keys : remote_cluster_name
      if remote_cluster_name != cluster_name
    ]
  }
}
