locals {
  # ============================================================
  # Project and Cluster Definitions
  # ============================================================

  project_suffix = "devkorea"
  aks_cluster_instances = {
    # "${local.project_suffix}-aks-1" = 0 --- IGNORE UNTIL THE SUB IS REACTIVATED ---
  }
  nks_cluster_instances = {
    "${local.project_suffix}-nks-1" = 0
    "${local.project_suffix}-nks-2" = 1
  }

  # ============================================================
  # Network Configuration Bases
  # ============================================================

  pod_cidr_base     = "10.240.0.0/12"
  service_cidr_base = "10.16.0.0/12"
  vnet_cidr_base    = "10.0.0.0/8"

  # Calculate non-overlapping CIDRs per module
  # Each module gets a /9 slice from the /8 base
  naver_vpc_cidr = cidrsubnet(local.vnet_cidr_base, 1, 0)  # 10.0.0.0/9
  azure_vnet_cidr = cidrsubnet(local.vnet_cidr_base, 1, 1) # 10.128.0.0/9

  # ============================================================
  # Multicluster Configuration
  # ============================================================

  all_cluster_instances = merge(local.aks_cluster_instances, local.nks_cluster_instances)

  # Map of cluster -> list of other clusters (for reference)
  other_clusters = {
    for cluster_name, _ in local.all_cluster_instances : cluster_name => [
      for remote_cluster_name, _ in local.all_cluster_instances : remote_cluster_name
      if remote_cluster_name != cluster_name
    ]
  }

  # Flattened map for linkerd credentials: "source->target" => {source, target}
  linkerd_credential_pairs = {
    for pair in flatten([
      for source, targets in local.other_clusters : [
        for target in targets : {
          key    = "${source}->${target}"
          source = source
          target = target
        }
      ]
    ]) : pair.key => pair
  }
}
