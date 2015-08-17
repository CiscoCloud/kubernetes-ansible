variable cluster_name { }

resource "openstack_compute_secgroup_v2" "cluster" {
    name = "${ var.cluster_name }"
    description = "Security Group for ${ var.cluster_name }"
    rule {
        from_port = 1
        to_port = 65535
        ip_protocol = "tcp"
        self = true
    }
    rule {
        from_port = 1
        to_port = 65535
        ip_protocol = "udp"
        self = true
    }
    rule {
        from_port = 443
        to_port = 443
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
}

output "cluster_name" {
    value = "${ openstack_compute_secgroup_v2.cluster.name }"
}
