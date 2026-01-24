# ============================================================
# Cluster RBAC Configuration
# ============================================================

variable "cluster_name" {
  description = "Name of the cluster for resource naming"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the argocd namespace"
  type        = bool
  default     = true
}
