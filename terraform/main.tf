module "naver_infrastructure" {
    source            = "./naver"
    project_suffix    = local.project_suffix
    cluster_instances = local.nks_cluster_instances
    vpc_cidr_base     = local.naver_vpc_cidr
    account_id        = var.account_id
}

# module "azure_infrastructure" {
#     source            = "./azure"
#     project_suffix    = local.project_suffix
#     cluster_instances = local.aks_cluster_instances
#     vnet_cidr_base    = local.azure_vnet_cidr
#     pod_cidr_base     = local.pod_cidr_base
#     service_cidr_base = local.service_cidr_base
# }


# ============================================================
# Linkerd Setup - Certificates (once)
# ============================================================

module "linkerd_certificates" {
  source = "./linkerd/certificates"
}

# ============================================================
# Linkerd Setup - License (per cluster)
# ============================================================

# module "linkerd_license_aks_1" {
#   source = "./linkerd/license"

#   depends_on = [module.naver_infrastructure]

#   providers = {
#     kubernetes = kubernetes.devkorea_aks_1
#   }

#   linkerd_enterprise_license = var.linkerd_enterprise_license
# }

module "linkerd_license_nks_1" {
  source = "./linkerd/license"

  depends_on = [module.naver_infrastructure]

  providers = {
    kubernetes = kubernetes.devkorea_nks_1
  }

  linkerd_enterprise_license = var.linkerd_enterprise_license
}

module "linkerd_license_nks_2" {
  source = "./linkerd/license"

  depends_on = [module.naver_infrastructure]

  providers = {
    kubernetes = kubernetes.devkorea_nks_2
  }

  linkerd_enterprise_license = var.linkerd_enterprise_license
}

# ============================================================
# ArgoCD Setup - Cluster RBAC (per cluster)
# ============================================================

# module "argocd_cluster_aks_1" {
#   source = "./argo/cluster"

#   depends_on = [module.naver_infrastructure]

#   providers = {
#     kubernetes = kubernetes.devkorea_aks_1
#   }

#   cluster_name     = "devkorea-aks-1"
#   create_namespace = true
# }

module "argocd_cluster_nks_1" {
  source = "./argo/cluster"

  depends_on = [module.naver_infrastructure]

  providers = {
    kubernetes = kubernetes.devkorea_nks_1
  }

  cluster_name     = "devkorea-nks-1"
  create_namespace = true
}

module "argocd_cluster_nks_2" {
  source = "./argo/cluster"

  depends_on = [module.naver_infrastructure]

  providers = {
    kubernetes = kubernetes.devkorea_nks_2
  }

  cluster_name     = "devkorea-nks-2"
  create_namespace = true
}

# ============================================================
# ArgoCD Setup - Helm Release (deploys ArgoCD server)
# ============================================================

module "argocd_helm" {
  source = "./argo/helm"

  depends_on = [
    # module.argocd_cluster_aks_1,
    module.argocd_cluster_nks_1,
    module.argocd_cluster_nks_2,
  ]

  providers = {
    helm       = helm
    kubernetes = kubernetes.devkorea_nks_1
  }

  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
}

# ============================================================
# ArgoCD Setup - Resources (clusters, projects, apps)
# Requires argocd provider to be configured after helm release
# ============================================================

module "argocd_resources" {
  source = "./argo/resources"

  depends_on = [module.argocd_helm]

  cluster_instances = local.all_cluster_instances
  kube_configs      = module.naver_infrastructure.kube_configs
  other_clusters    = local.other_clusters

  cluster_tokens = {
    # "devkorea-aks-1" = module.argocd_cluster_aks_1.manager_token
    "devkorea-nks-1" = module.argocd_cluster_nks_1.manager_token
    "devkorea-nks-2" = module.argocd_cluster_nks_2.manager_token
  }

  linkerd_enterprise_version = var.linkerd_enterprise_version
  trust_anchor_cert_pem      = module.linkerd_certificates.trust_anchor_cert_pem
  issuer_cert_pem            = module.linkerd_certificates.issuer_cert_pem
  issuer_private_key_pem     = module.linkerd_certificates.issuer_private_key_pem
}
