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

    Run the following commands to generate the linkerd links between clusters:

    %{for pair in local.linkerd_credential_pairs~}
    # Link from ${pair.source} to ${pair.target}
    linkerd --context=${pair.source} multicluster link-gen --cluster-name=${pair.source} --gateway=true | kubectl --context=${pair.target} apply -f -

    %{endfor~}
    ============================================================
  EOT
}
