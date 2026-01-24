# ============================================================
# Naver Cloud Variables
# ============================================================

variable "access_key" {
  description = "Naver Cloud access key."
  type        = string
}

variable "secret_key" {
  description = "Naver Cloud secret key."
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Naver Cloud account ID"
  type        = string
  sensitive   = true
}

# ============================================================
# Azure Variables
# ============================================================


variable "tenant_id" {
  description = "The Tenant ID for the Azure subscription."
  type        = string
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure subscription."
  type        = string
}

variable "client_id" {
  description = "The Client ID for the Azure Service Principal."
  type        = string
}

variable "client_secret" {
  description = "The Client Secret for the Azure Service Principal."
  type        = string
  sensitive   = true
}

# ============================================================
# ArgoCD Variables
# ============================================================

variable "argocd_admin_password" {
  description = "Argo CD admin password used by the provider when port-forwarding to the API server."
  type        = string
  sensitive   = true
}

variable "argocd_admin_password_bcrypt" {
  description = "Argo CD admin password bcrypt hashed."
  type        = string
  sensitive   = true
}

# ============================================================
# Linkerd Variables
# ============================================================

variable "linkerd_enterprise_license" {
  description = "Linkerd Enterprise license key."
  type      = string
  sensitive = true
}

variable "linkerd_enterprise_version" {
  description = "Linkerd Enterprise version to install."
  type    = string
  default = "2.19.4"
}
