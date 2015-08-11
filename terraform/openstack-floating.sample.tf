module "dc2-keypair" {
  source = "./terraform/openstack/keypair"
  auth_url = ""
  tenant_id = ""
  tenant_name = ""
  public_key = ""
  keypair_name = ""
}

module "dc2-secgroup" {
    source = "./terraform/openstack/secgroup"
    cluster_name = "k8s-cluster"
}

module "dc2-hosts-floating" {
  source = "./terraform/openstack/hosts-floating"
  auth_url = ""
  datacenter = "dc2"
  tenant_id = ""
  tenant_name = ""
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
