variable datacenter { default = "openstack" }
variable master_flavor { }
variable node_flavor { }
variable keypair_name { }
variable image_name { }
variable master_count {}
variable node_count {}
variable security_groups {  }
variable floating_pool {}
variable external_net_id { }
variable subnet_cidr { default = "10.10.10.0/24" }
variable ip_version { default = "4" }
variable short_name { default = "k8s" }
variable long_name { default = "kubernertes" }
variable host_domain { default = "novalocal" }
variable ssh_user { default = "centos" }

resource "template_file" "cloud-init-master" {
  count         = "${ var.master_count }"
  template      = "terraform/openstack/cloud-config/user-data.yml"
  vars {
    hostname    = "${ var.short_name }-master-${ format("%02d", count.index+1) }"
    host_domain = "${ var.host_domain }"
  }
}

resource "template_file" "cloud-init-node" {
  count         = "${ var.node_count }"
  template      = "terraform/openstack/cloud-config/user-data.yml"
  vars {
    hostname    = "${ var.short_name }-node-${ format("%02d", count.index+1) }"
    host_domain = "${ var.host_domain }"
  }
}

resource "openstack_compute_instance_v2" "master" {
  floating_ip = "${ element(openstack_compute_floatingip_v2.ms-master-floatip.*.address, count.index) }"
  name                  = "${ var.short_name}-master-${format("%02d", count.index+1) }"
  key_pair              = "${ var.keypair_name }"
  image_name            = "${ var.image_name }"
  flavor_name           = "${ var.master_flavor }"
  security_groups       = [ "${ var.security_groups }", "default" ]
  network               = { uuid = "${ openstack_networking_network_v2.ms-network.id }" }
  metadata              = {
                            dc = "${var.datacenter}"
                            role = "master"
                            ssh_user = "${ var.ssh_user }"
                          }
  count                 = "${ var.master_count }"
  user_data             = "${ element(template_file.cloud-init-master.*.rendered, count.index) }"
}

resource "openstack_compute_instance_v2" "node" {
  floating_ip = "${ element(openstack_compute_floatingip_v2.ms-node-floatip.*.address, count.index) }"
  name                  = "${ var.short_name}-node-${format("%02d", count.index+1) }"
  key_pair              = "${ var.keypair_name }"
  image_name            = "${ var.image_name }"
  flavor_name           = "${ var.node_flavor }"
  security_groups       = [ "${ var.security_groups }", "default" ]
  network               = { uuid = "${ openstack_networking_network_v2.ms-network.id }" }
  metadata              = {
                            dc = "${var.datacenter}"
                            role = "node"
                            ssh_user = "${ var.ssh_user }"
                          }
  count                 = "${ var.node_count }"
  user_data             = "${ element(template_file.cloud-init-node.*.rendered, count.index) }"
}

resource "openstack_compute_floatingip_v2" "ms-master-floatip" {
  pool 	     = "${ var.floating_pool }"
  count      = "${ var.master_count }"
  depends_on = [ "openstack_networking_router_v2.ms-router",
                 "openstack_networking_network_v2.ms-network",
                 "openstack_networking_router_interface_v2.ms-router-interface" ]
}

resource "openstack_compute_floatingip_v2" "ms-node-floatip" {
  pool       = "${ var.floating_pool }"
  count      = "${ var.node_count }"
  depends_on = [ "openstack_networking_router_v2.ms-router",
                 "openstack_networking_network_v2.ms-network",
                 "openstack_networking_router_interface_v2.ms-router-interface" ]
}

resource "openstack_networking_network_v2" "ms-network" {
  name = "${ var.short_name }-network"
}

resource "openstack_networking_subnet_v2" "ms-subnet" {
  name          ="${ var.short_name }-subnet"
  network_id    = "${ openstack_networking_network_v2.ms-network.id }"
  cidr          = "${ var.subnet_cidr }"
  ip_version    = "${ var.ip_version }"
}

resource "openstack_networking_router_v2" "ms-router" {
  name             = "${ var.short_name }-router"
  external_gateway = "${ var.external_net_id }"
}

resource "openstack_networking_router_interface_v2" "ms-router-interface" {
  router_id = "${ openstack_networking_router_v2.ms-router.id }"
  subnet_id = "${ openstack_networking_subnet_v2.ms-subnet.id }"
}
