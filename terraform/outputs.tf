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

    Step 4: Verify Linkerd multicluster links
    -------------------------------------------

    4a. Check Link resources status (should show "Alive: true"):
    %{for cluster_name, _ in local.all_cluster_instances~}
    linkerd --context=${cluster_name} multicluster check
    %{endfor~}

    4b. List linked clusters and gateways:
    %{for cluster_name, _ in local.all_cluster_instances~}
    linkerd --context=${cluster_name} multicluster gateways
    %{endfor~}

    4c. View pods and services in simple-app namespace:
    %{for cluster_name, _ in local.all_cluster_instances~}
    kubectl get pods,svc --context=${cluster_name} -o wide -n simple-app
    %{endfor~}

    4d. View mirrored services (services from remote clusters):
    %{for cluster_name, _ in local.all_cluster_instances~}
    kubectl get svc --context=${cluster_name} -n simple-app -l mirror.linkerd.io/mirrored-service=true
    %{endfor~}

    4e. Test cross-cluster connectivity via gateway (from ${keys(local.all_cluster_instances)[0]}):
    %{for remote_cluster in local.other_clusters[keys(local.all_cluster_instances)[0]]~}
    kubectl exec -it -n simple-app curl-meshed -c curl --context=${keys(local.all_cluster_instances)[0]} -- curl -sv simple-app-v1-gateway-${remote_cluster}.simple-app.svc.cluster.local:80
    %{endfor~}

    4f. Test cross-cluster connectivity via mirrored services (from ${keys(local.all_cluster_instances)[0]}):
    %{for remote_cluster in local.other_clusters[keys(local.all_cluster_instances)[0]]~}
    kubectl exec -it -n simple-app curl-meshed -c curl --context=${keys(local.all_cluster_instances)[0]} -- curl -sv simple-app-v1-mirrored-${remote_cluster}.simple-app.svc.cluster.local:80
    %{endfor~}

    4g. Test federated service (load balances across all clusters):
    kubectl exec -it -n simple-app curl-meshed -c curl --context=${keys(local.all_cluster_instances)[0]} -- curl -sv simple-app-v1-federated-federated.simple-app.svc.cluster.local:80

    ============================================================
  EOT
}
