locals {
  vpc_peering_pairs = {
    for pair in flatten([
      for source_key, source_val in var.cluster_instances : [
        for target_key, target_val in var.cluster_instances : {
          key    = "${source_key}-to-${target_key}"
          source = source_key
          target = target_key
        } if source_val < target_val
      ]
    ]) : pair.key => pair
  }
}
