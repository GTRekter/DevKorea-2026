# ============================================================
# Project and Cluster Definitions
# ============================================================

variable "project_suffix" {
  description = "Project name"
  type        = string
}

variable "cluster_instances" {
  description = "AKS cluster instances"
}

variable "vnet_cidr_base" {
  description = "Azure VNet CIDR base"
  type        = string
}

variable "pod_cidr_base" {
  description = "Pod CIDR base for AKS clusters"
  type        = string
}

variable "service_cidr_base" {
  description = "Service CIDR base for AKS clusters"
  type        = string
}
