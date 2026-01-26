# ============================================================
# Cluster Configuration
# ============================================================

variable "cluster_instances" {
  description = "Map of cluster names to their indices"
  type        = map(number)
}

variable "kube_configs" {
  description = "Map of cluster names to their kube configs"
  type = map(object({
    host                   = string
    cluster_ca_certificate = string
    id                     = optional(string)
  }))
  sensitive = true
}

variable "cluster_tokens" {
  description = "Map of cluster names to their ArgoCD manager tokens"
  type        = map(string)
  sensitive   = true
}

variable "other_clusters" {
  description = "Map of cluster name to list of other cluster names for multicluster setup"
  type        = map(list(string))
}

# ============================================================
# Linkerd Configuration
# ============================================================

variable "linkerd_enterprise_version" {
  description = "Linkerd Enterprise version to install"
  type        = string
  default     = "2.19.4"
}

variable "trust_anchor_cert_pem" {
  description = "Trust anchor certificate PEM for Linkerd identity"
  type        = string
  sensitive   = true
}

variable "issuer_cert_pem" {
  description = "Issuer certificate PEM for Linkerd identity"
  type        = string
  sensitive   = true
}

variable "issuer_private_key_pem" {
  description = "Issuer private key PEM for Linkerd identity"
  type        = string
  sensitive   = true
}
