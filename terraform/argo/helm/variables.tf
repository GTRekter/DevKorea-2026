# ============================================================
# ArgoCD Helm Variables
# ============================================================

variable "argocd_admin_password_bcrypt" {
  description = "Argo CD admin password bcrypt hashed"
  type        = string
  sensitive   = true
}
