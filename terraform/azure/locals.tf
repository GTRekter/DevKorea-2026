locals {
  vnet_peering_pairs = [
    for pair in flatten([
      for source_key, source_val in var.cluster_instances : [
        for target_key, target_val in var.cluster_instances : {
          src_key = source_key
          dst_key = target_key
        } if source_val < target_val
      ]
    ]) : pair
  ]
}
