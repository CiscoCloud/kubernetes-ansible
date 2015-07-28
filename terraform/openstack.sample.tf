variable prefix_name { default = "kube" }

module "dc2-keypair" {
    source = "./terraform/openstack/keypair"
    auth_url = ""
    tenant_id = ""
    tenant_name = ""
    public_key = "~/.ssh/id_rsa.pub"
    keypair_name = "${ var.prefix_name }-key"
}

module "dc2-secgroup" {
    source = "./terraform/openstack/secgroup"
    auth_url = ""
    tenant_id = ""
    tenant_name = ""
    cluster_name = "${ var.prefix_name }-cluster"
}

module "dc2-hosts" {
    source = "./terraform/openstack/hosts"
    auth_url = ""
    tenant_id = ""
    tenant_name = ""
    datacenter = "dc2"
    short_name = "${ var.prefix_name }"
    control_flavor_name = ""
    resource_flavor_name  = ""
    net_id = ""
    subnet_id = ""
    floating_pool = ""
    image_name = ""
    keypair_name = "${ module.dc2-keypair.keypair_name }"
    security_groups = "${ module.dc2-secgroup.cluster_name }"
    ssh_user = "centos"
    control_count = 1
    resource_count = 3
    security_groups = ""
}
