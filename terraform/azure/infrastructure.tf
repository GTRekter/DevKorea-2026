# ============================================================
# Resource Group
# ============================================================

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project_suffix}-rg"
  location = "Korea Central"
}

# ============================================================
# Network Resources
# ============================================================

resource "azurerm_virtual_network" "virtual_network" {
  for_each = var.cluster_instances

  name                = "${each.key}-vnet"
  address_space       = [cidrsubnet(var.vnet_cidr_base, 8, each.value)]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnets" {
  for_each = var.cluster_instances

  name                 = "${each.key}-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network[each.key].name
  address_prefixes     = [cidrsubnet(tolist(azurerm_virtual_network.virtual_network[each.key].address_space)[0], 8, 0)]
}

# ============================================================
# Kubernetes Resources
# ============================================================

resource "azurerm_kubernetes_cluster" "kubernetes_clusters" {
  for_each = var.cluster_instances

  name                = each.key
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "${each.key}-dns"
  default_node_pool {
    name           = "default"
    zones          = ["1", "2", "3"]
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.subnets[each.key].id
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }
  identity {
    type = "SystemAssigned"
  }
  node_resource_group               = "${each.key}-infra-rg"
  oidc_issuer_enabled               = false
  workload_identity_enabled         = false
  role_based_access_control_enabled = true
  local_account_disabled            = false
  azure_policy_enabled              = false
  image_cleaner_enabled             = false
  workload_autoscaler_profile {
    keda_enabled = true
  }
  network_profile {
    network_plugin = "kubenet"
    pod_cidr       = cidrsubnet(var.pod_cidr_base, 4, each.value)
    service_cidr   = cidrsubnet(var.service_cidr_base, 4, each.value)
    dns_service_ip = cidrhost(cidrsubnet(var.service_cidr_base, 4, each.value), 10)
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "linux_node_pool" {
  for_each = var.cluster_instances

  name                  = "linux"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes_clusters[each.key].id
  node_count            = 3
  vm_size               = "Standard_D4s_v3"
  os_type               = "Linux"
  mode                  = "User"
  zones                 = ["1", "2", "3"]
  vnet_subnet_id        = azurerm_subnet.subnets[each.key].id
  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
}

# resource "azurerm_kubernetes_cluster_node_pool" "windows_node_pool" {
#   for_each = azurerm_kubernetes_cluster.kubernetes_clusters
#   name                  = "win"
#   kubernetes_cluster_id = each.value.id
#   node_count            = 3
#   vm_size               = "Standard_D4s_v3"
#   os_type               = "Windows"
#   mode                  = "User"
#   zones                 = ["1", "2", "3"]
# }
