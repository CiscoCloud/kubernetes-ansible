variable auth_url {}
variable tenant_id {}
variable tenant_name {}

provider "openstack" {
  auth_url = "${ var.auth_url }"
  tenant_id = "${ var.tenant_id }"
  tenant_name = "${ var.tenant_name }"
}

module "dc2-keypair" {
  source = "./terraform/openstack/keypair"
  public_key = ""
  keypair_name = ""
}

module "dc2-secgroup" {
  source = "./terraform/openstack/secgroup"
  cluster_name = "k8s-cluster"
}

module "dc2-hosts-floating" {
  source = "./terraform/openstack/hosts-floating"
  datacenter = "dc2"
  master_flavor = ""
  node_flavor = ""
  image_name = ""
  keypair_name = "${ module.dc2-keypair.keypair_name }"
  security_groups = "${ module.dc2-secgroup.cluster_name }"
  master_count = 1
  node_count = 2
  floating_pool = ""
  external_net_id = ""
}
