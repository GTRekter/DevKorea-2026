  # ============================================================
  # Project and Cluster Definitions
  # ============================================================

variable "project_suffix" {
    description = "Project name"
    type        = string
}

variable "cluster_instances" {
    description = "NKS cluster instances"
}

variable "vpc_cidr_base" {
    description = "Naver Cloud Platform VPC CIDR base"
    type        = string
}

variable "account_id" {
    description = "Naver Cloud Platform Account ID"
    type        = string  
}
