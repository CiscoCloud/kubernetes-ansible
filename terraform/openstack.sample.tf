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

module "dc2-hosts" {
  source = "./terraform/openstack/hosts"
  auth_url = ""
  datacenter = "dc2"
  tenant_id = ""
  tenant_name = ""
  master_flavor = ""
  node_flavor = ""
  net_id = ""
  image_name = ""
  keypair_name = "${ module.dc2-keypair.keypair_name }"
  master_count = 1
  node_count = 2
  security_groups = "${ module.dc2-secgroup.cluster_name }"
  glusterfs_volume_size = 100
}
