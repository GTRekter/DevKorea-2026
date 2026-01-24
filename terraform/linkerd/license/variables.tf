# ============================================================
# License Configuration
# ============================================================

variable "linkerd_enterprise_license" {
  description = "Linkerd Enterprise license key"
  type        = string
  sensitive   = true
}
