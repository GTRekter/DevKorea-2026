output "kube_config" {
  description = "Raw kubeconfig per AKS cluster instance."
  value       = { for key, cluster in azurerm_kubernetes_cluster.kubernetes_clusters : key => cluster.kube_config_raw }
  sensitive   = true
}
