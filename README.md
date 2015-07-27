## Ansible playbook that provisions k8s cluster with flannel network overlay.

### Main goals

 - Install etcd server
 - Install docker
 - Install flanneld and put config in etcd
 - Install Kubernetes package from CentOS vitr7-testing repo
 - Configure Kubernetes master
 - Configure Kubernetes minion
 - Install kube-dns service discovery and DNS resolution pod

### Prepare environment

There is 3 main roles:
 - Etcd server
 - Kubernetes master
 - Kubernetes node (minion)

You can safely combine `etcd` and `kubernetes master` on one host, eventually you even can run `kubernetes minion` on that host also.

For this setup you will need 1 host that would be `kubernetes master` and some amount of hosts as `minions`.
I suggest you using at least 2 minion nodes to test flannel or any other networking for kubernetes.

If you already have prepared hosts you can provide simple ansible inventory (sample is in root of project) and update group variables in `group_vars/all.yml` if it's needed.

Also you can provision hosts on OpenStack using Terraform. Examples provided in `terraform/` folder. Copy sample `.tf` file in project home, fill in all fields and provide number of nodes ( e.g. 1 control and 3 worker nodes ).

### Firewall notice
If you running on some cloud provider make sure that firewall configuration permits traffic beetween nodes.

Port list on roles:
TBD


### Run ansible playbooks

This guide not provides any information like "Getting started with Ansible". So make sure that ansible can rearch your hosts. At least you can "ping" them like `ansible -m ping all`

First of all look into `group_vars/all.yml` and make changes if needed.

To run ansible on hosts you prepared run:

```
ansible-playbook -i inventory setup.yml
```

If you used Terraform to provision your hosts you can use script that provides dynamic inventory from `.tfstate`

```
ansible-playbook -i plugins/inventory/terraform.py setup.yml
```
Then if needed you can get list of hosts with `terraform.py` and put them directly in your `/etc/hosts` file.

```
./plugins/inventory/terraform.py --hostfile >> /etc/hosts
```

### Check cluster deployment

TBD
