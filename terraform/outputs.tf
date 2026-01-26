# ============================================================
# Terraform Outputs
# ============================================================

output "argocd_url" {
  description = "The ArgoCD server URL"
  value       = "https://${module.argocd_helm.argocd_server_host}"
}

output "linkerd_link_instructions" {
  description = "Instructions to generate Linkerd multicluster links"
  value       = <<-EOT

    ============================================================
    Linkerd Multicluster Link Generation Instructions
    ============================================================

    Prerequisites: Run these commands from the project root directory
    -----------------------------------------------------------------
    mkdir -p ./kubeconfigs

    Step 1a: Generate kubeconfigs for NKS clusters (Naver Cloud)
    ------------------------------------------------------------
    %{for cluster_name, _ in local.nks_cluster_instances~}
    CLUSTER_UUID_${replace(cluster_name, "-", "_")}=$(terraform -chdir=terraform state show 'module.naver_infrastructure.ncloud_nks_cluster.clusters["${cluster_name}"]' | awk -F'"' '/uuid/ {print $2}')
    ncp-iam-authenticator create-kubeconfig --region KR --clusterUuid "$CLUSTER_UUID_${replace(cluster_name, "-", "_")}" --output ./kubeconfigs/kubeconfig-${cluster_name}.yaml
    kubectl config rename-context "nks_kr_${cluster_name}_$CLUSTER_UUID_${replace(cluster_name, "-", "_")}" "${cluster_name}" --kubeconfig=./kubeconfigs/kubeconfig-${cluster_name}.yaml

    %{endfor~}

    Step 1b: Generate kubeconfigs for AKS clusters (Azure)
    ------------------------------------------------------
    %{for cluster_name, _ in local.aks_cluster_instances~}
    az aks get-credentials --resource-group ${local.project_suffix}-rg --name ${cluster_name} --file ./kubeconfigs/kubeconfig-${cluster_name}.yaml

    %{endfor~}

    Step 2: Merge kubeconfigs and set contexts
    ------------------------------------------
    export KUBECONFIG=%{for idx, cluster_name in keys(local.all_cluster_instances)~}./kubeconfigs/kubeconfig-${cluster_name}.yaml%{if idx < length(local.all_cluster_instances) - 1}:%{endif}%{endfor~}
    kubectl config get-contexts

    Step 3: Generate Linkerd multicluster links
    -------------------------------------------
    %{for pair in local.linkerd_credential_pairs~}
   linkerd --context=${pair.source} multicluster link-gen --cluster-name=${pair.source} --gateway=true | kubectl --context=${pair.target} apply -f -

    %{endfor~}
    ============================================================
  EOT
}
