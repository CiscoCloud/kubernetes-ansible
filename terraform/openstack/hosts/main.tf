variable auth_url { }
variable tenant_id { }
variable tenant_name { }
variable datacenter { default = "openstack" }
variable short_name { default = "kube" }
variable long_name { default = "kubernetes-on-openstack" }
variable control_flavor_name { }
variable resource_flavor_name { }
variable net_id { }
variable keypair_name { }
variable image_name { }
variable control_count {}
variable resource_count {}
variable security_groups {}

provider "openstack" {
  auth_url = "${ var.auth_url }"
  tenant_id = "${ var.tenant_id }"
  tenant_name = "${ var.tenant_name }"
}

resource "openstack_compute_instance_v2" "control" {
  name = "${ var.short_name}-control-${format("%02d", count.index+1) }"
  key_pair = "${ var.keypair_name }"
  image_name = "${ var.image_name }"
  flavor_name = "${ var.control_flavor_name }"
  # default security group usually provides you the ability to ssh into the host
  security_groups = [ "${ var.security_groups }", "default" ]
  network = { uuid = "${ var.net_id }" }
  metadata = {
    dc = "${var.datacenter}"
    role = "control"
  }
  count = "${ var.control_count }"
}

resource "openstack_compute_instance_v2" "resource" {
  name = "${ var.short_name}-worker-${format("%02d", count.index+1) }"
  key_pair = "${ var.keypair_name }"
  image_name = "${ var.image_name }"
  flavor_name = "${ var.resource_flavor_name }"
  security_groups = [ "${ var.security_groups }", "default" ]
  network = { uuid = "${ var.net_id }" }
  metadata = {
    dc = "${var.datacenter}"
    role = "worker"
  }
  count = "${ var.resource_count }"
}

