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

variable "linkerd_enterprise_license" {
  type      = string
  sensitive = true
}

variable "linkerd_enterprise_version" {
  type    = string
  default = "2.19.4"
}

variable "argocd_admin_password" {
  description = "Argo CD admin password used by the provider when port-forwarding to the API server."
  type        = string
  sensitive   = true
}
