# ============================================================
# Certificate Configuration
# ============================================================

variable "trust_anchor_validity_hours" {
  description = "Validity period for trust anchor certificate in hours"
  type        = number
  default     = 87600 # ~10 years
}

variable "issuer_validity_hours" {
  description = "Validity period for issuer certificate in hours"
  type        = number
  default     = 8760 # ~1 year
}
