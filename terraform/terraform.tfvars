# Complete the required configuration below and copy this file and
# openstack.sample.tf or openstack-floating.sample.tf to the root directory
# before running terraform commands

# Configuration variables

auth_url = ""
tenant_id = ""
tenant_name = ""
public_key = ""
keypair_name = ""
cluster_name = ""
image_name = ""
master_flavor = ""
node_flavor = ""
master_count = "3"
node_count = "3"
datacenter = ""
ssh_user = "centos"
short_name = "k8s"
host_domain = "novalocal"

# If using openstack-floating.sample.tf, set the two variables below

floating_pool = ""
external_net_id = ""
subnet_cidr = "10.0.0.0/24"

# If using openstack.sample.tf, set the following

net_id = ""
