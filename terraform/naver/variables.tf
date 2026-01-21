variable "project_suffix" {
  description = "Suffix used to name Naver Cloud resources."
  type        = string
  default     = "devkorea"
}

variable "region" {
  description = "Naver Cloud region code."
  type        = string
  default     = "KR"
}

variable "zone" {
  description = "Naver Cloud zone for subnet and cluster placement."
  type        = string
  default     = "KR-1"
}

variable "node_count" {
  description = "Number of nodes in the NKS node pool."
  type        = number
  default     = 2
}

variable "node_storage_size" {
  description = "Root disk size (GB) for nodes."
  type        = number
  default     = 200
}
