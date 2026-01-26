# ============================================================
# VPC
# ============================================================

resource "ncloud_vpc" "vpc" {
  for_each        = var.cluster_instances
  name            = "${var.project_suffix}-vpc-${each.value}"
  ipv4_cidr_block = cidrsubnet(var.vpc_cidr_base, 8, each.value)
}

# ============================================================
# Subnets (3 per VPC: work + lb private + lb public)
# ============================================================

resource "ncloud_subnet" "work" {
  for_each = var.cluster_instances

  name           = "${var.project_suffix}-subnet-${each.value}"
  vpc_no         = ncloud_vpc.vpc[each.key].id
  subnet         = cidrsubnet(cidrsubnet(var.vpc_cidr_base, 8, each.value), 8, 1)
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc[each.key].default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "lb_private" {
  for_each = var.cluster_instances

  name           = "${var.project_suffix}-lb-subnet-${each.value}"
  vpc_no         = ncloud_vpc.vpc[each.key].id
  subnet         = cidrsubnet(cidrsubnet(var.vpc_cidr_base, 8, each.value), 8, 100)
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc[each.key].default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "natgw" {
  for_each = var.cluster_instances

  name           = "${var.project_suffix}-natgw-subnet-${each.value}"
  vpc_no         = ncloud_vpc.vpc[each.key].id
  subnet         = cidrsubnet(cidrsubnet(var.vpc_cidr_base, 8, each.value), 8, 102)
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc[each.key].default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "NATGW"
}

resource "ncloud_subnet" "lb_public" {
  for_each = var.cluster_instances

  name           = "${var.project_suffix}-lb-pub-subnet-${each.value}"
  vpc_no         = ncloud_vpc.vpc[each.key].id
  subnet         = cidrsubnet(cidrsubnet(var.vpc_cidr_base, 8, each.value), 8, 101)
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc[each.key].default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
}

resource "ncloud_nat_gateway" "natgw" {
  for_each = var.cluster_instances

  vpc_no    = ncloud_vpc.vpc[each.key].id
  subnet_no = ncloud_subnet.natgw[each.key].id
  zone      = "KR-1"
  name      = "${var.project_suffix}-natgw-${each.value}"
}

resource "ncloud_route" "default_private_to_natgw" {
  for_each = var.cluster_instances

  route_table_no         = ncloud_vpc.vpc[each.key].default_private_route_table_no
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = ncloud_nat_gateway.natgw[each.key].name
  target_no              = ncloud_nat_gateway.natgw[each.key].id
}

# ============================================================
# Load Balancer for Linkerd Gateway
# ============================================================

resource "ncloud_lb" "linkerd_gateway" {
  for_each = var.cluster_instances

  name           = "${var.project_suffix}-linkerd-gw-${each.value}"
  type           = "NETWORK"
  network_type   = "PUBLIC"
  subnet_no_list = [ncloud_subnet.lb_public[each.key].id]
}

resource "ncloud_lb_target_group" "linkerd_gateway" {
  for_each = var.cluster_instances

  name        = "${var.project_suffix}-linkerd-tg-${each.value}"
  vpc_no      = ncloud_vpc.vpc[each.key].id
  protocol    = "TCP"
  target_type = "VSVR"
  port        = 4143

  health_check {
    protocol       = "TCP"
    port           = 4143
    cycle          = 30
    up_threshold   = 2
    down_threshold = 2
  }
}

resource "ncloud_lb_listener" "linkerd_gateway" {
  for_each = var.cluster_instances

  load_balancer_no = ncloud_lb.linkerd_gateway[each.key].id
  protocol         = "TCP"
  port             = 4143
  target_group_no  = ncloud_lb_target_group.linkerd_gateway[each.key].id
}


# ============================================================
# VPC Peering
# ============================================================

resource "ncloud_vpc_peering" "peerings" {
  for_each = local.vpc_peering_pairs

  name          = "${var.project_suffix}-vpc-${var.cluster_instances[each.value.source]}-to-${var.cluster_instances[each.value.target]}"
  source_vpc_no = ncloud_vpc.vpc[each.value.source].id
  target_vpc_no = ncloud_vpc.vpc[each.value.target].id
}

# ============================================================
# NKS (cluster per VPC)
# ============================================================

resource "random_integer" "login_key_suffix" {
  min = 1
  max = 50000
}

resource "ncloud_login_key" "login_key" {
  for_each = var.cluster_instances

  key_name = "${each.key}-login-key-${random_integer.login_key_suffix.result}"
}

resource "ncloud_nks_cluster" "clusters" {
  for_each = var.cluster_instances

  name                 = each.key
  hypervisor_code      = "KVM"
  cluster_type         = "SVR.VNKS.STAND.C002.M008.G003"
  login_key_name       = ncloud_login_key.login_key[each.key].key_name
  vpc_no               = ncloud_vpc.vpc[each.key].id
  zone                 = "KR-1"
  public_network       = false
  kube_network_plugin  = "cilium"
  auth_type            = "API"
  k8s_version          = "1.33.4-nks.2"
  subnet_no_list       = [ncloud_subnet.work[each.key].id]
  lb_private_subnet_no = ncloud_subnet.lb_private[each.key].id
  lb_public_subnet_no  = ncloud_subnet.lb_public[each.key].id
  access_entries {
    entry = "nrn:PUB:Account::${var.account_id}:Customer/static"
    policies {
      type  = "NKSClusterAdminPolicy"
      scope = "cluster"
    }
  }
}

resource "ncloud_nks_node_pool" "node_pools" {
  depends_on = [ncloud_nks_cluster.clusters]
  for_each   = var.cluster_instances

  node_pool_name   = "${var.project_suffix}-np-${each.value}"
  cluster_uuid     = ncloud_nks_cluster.clusters[each.key].uuid
  node_count       = "1"
  server_spec_code = data.ncloud_nks_server_products.product.products[0].value
  storage_size     = "100"
  software_code    = data.ncloud_nks_server_images.image.images[0].value
  autoscale {
    enabled = false
    min     = "0"
    max     = "0"
  }
}
