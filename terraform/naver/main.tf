terraform {
  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = ">= 2.5.0"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  region      = var.region
  support_vpc = true
}

resource "ncloud_vpc" "vpc" {
  name            = "${local.project_suffix}-vpc"
  ipv4_cidr_block = "10.0.0.0/16"
}

resource "ncloud_subnet" "subnet" {
  name           = "${local.project_suffix}-subnet"
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.0.1.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "subnet_lb" {
  name           = "${local.project_suffix}-lb-subnet"
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.0.100.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "subnet_lb_pub" {
  name           = "${local.project_suffix}-lb-pub-subnet"
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.0.101.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
}

resource "ncloud_login_key" "login_key" {
  key_name = "${local.project_suffix}-login-key"
}

resource "ncloud_nks_cluster" "cluster" {
  name                 = "${local.project_suffix}-cluster"
  hypervisor_code      = "KVM"
  cluster_type         = "SVR.VNKS.STAND.C002.M008.G003"
  login_key_name       = ncloud_login_key.login_key.key_name
  lb_private_subnet_no = ncloud_subnet.subnet_lb.id
  lb_public_subnet_no  = ncloud_subnet.subnet_lb_pub.id
  kube_network_plugin  = "cilium"
  subnet_no_list       = [ncloud_subnet.subnet.id]
  vpc_no               = ncloud_vpc.vpc.id
  public_network       = false
  zone                 = var.zone
}

resource "ncloud_nks_node_pool" "nks_node_pool" {
  node_pool_name   = "${local.project_suffix}-node-pool"
  cluster_uuid     = ncloud_nks_cluster.cluster.uuid
  node_count       = var.node_count
  server_spec_code = data.ncloud_nks_server_products.product.products[0].value
  storage_size     = var.node_storage_size
  software_code    = data.ncloud_nks_server_images.image.images[0].value
  autoscale {
    enabled = false
    min     = var.node_count
    max     = var.node_count
  }
}
