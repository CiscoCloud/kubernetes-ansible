## Install and configure Kubernetes on OpenStack using ansible and terraform

### Main goals

- Install etcd server
- Install docker
- Install flanneld and put config in etcd
- Install Kubernetes package
- Configure Kubernetes master
- Configure Kubernetes minion
- Install kube-dns service discovery and DNS resolution pod


### Available Addons

- DNS for Service Discovery
- Kubernetes UI
- Logging Service for containers

#### NOTE

Each addon is enabled by default but can be disabled by changing the options within `group_vars/all.yml`
All of the addons depend on the DNS addon for Service Discovery.


### Provision Openstack environment

- Install [terraform](http://www.terraform.io/downloads.html)

        # change 0.6.3 to the desired version
        wget -q -O terraform.zip https://dl.bintray.com/mitchellh/terraform/terraform_0.6.3_linux_amd64.zip
        unzip terraform.zip -d /usr/local/bin

- Install pip package (CentOS/RedHat)

        # yum install python-devel python-pip
        
- Install the OpenStack command-line clients

When following the instructions in this section, replace PROJECT with the lowercase name of the client to install, such as nova. Repeat for each client. The following values are valid:

        - barbican - Key Manager Service API
        - ceilometer - Telemetry API
        - cinder - Block Storage API and extensions
        - glance - Image service API
        - heat - Orchestration API
        - magnum - Containers service API
        - manila - Shared file systems API
        - mistral - Workflow service API
        - murano - Application catalog API
        - neutron - Networking API
        - nova - Compute API and extensions
        - sahara - Data Processing API
        - swift - Object Storage API
        - trove - Database service API
        - tuskar - Deployment service API
        - openstack - Common OpenStack client supporting multiple services

        # How to install with pip:
        pip install python-PROJECTclient
        (Replace PROJECT with the lowercase name of the client)

        # How to update with pip:
        pip install --upgrade python-PROJECTclient
        (Replace PROJECT with the lowercase name of the client)

        To remove the client, run the pip uninstall command:
        pip uninstall python-PROJECTclient
        (Replace PROJECT with the lowercase name of the client)

Additional OpenStack CLI information [here](http://docs.openstack.org/user-guide/common/cli_install_openstack_command_line_clients.html)

- Download Openstack RC file from Openstack Project Web Interface(Access & Security --> API Access)

        source openrc.sh
        # prompted for your password for the Openstack Project

- Provide configurations for Openstack
        (From GitHub branch https://github.com/CiscoCloud/kubernetes-ansible/tree/master/terraform)

        cp terraform/openstack.sample.tf openstack.tf
        cp terraform/terraform.tfvars terraform.tfvars

        # edit the terraform.tfvars file by providing the following
        
        - auth_url (found within *openrc.sh)
        - tenant_id (found within *openrc.sh)
        - tenant_name (found within *openrc.sh)
        - location of ssh public key and a unique name
        - VM Flavor for Master node (*nova flavor-list)
        - VM Flavor for Worker node (*nova flavor-list)
        - Network ID (*nova net-list)
        - OS Image Name (*nova image-list)
        - Number of worker nodes
        - size (GB) of storage for kubernetes master to use

        *nova - example if you using NOVA Compute API and extensions
        *openrc.sh - Openstack Project Web Interface

- Provision Environment

        terraform get (Get modules)
        terraform plan (Checking configuration)
        terraform apply (Apply )

- Verify SSH access to the hosts

        ansible -m ping all


### Firewall notice

If you are running on a cloud provider make sure that firewall configuration permits traffic between nodes. If you used terraform to provision environment then a security group has already been created for you.

Port list on roles:
TBD


### Prepare environment

There is 3 main roles:
 - etcd server
 - kubernetes master
 - kubernetes node (minion)

You can safely combine `etcd` and `kubernetes master` on one host, eventually you can run `kubernetes minion` on that host also.

For this setup you will need 1 host that would be `kubernetes master` and 2 or more hosts as `minions`.
At least 2 minion nodes are needed to use flannel or any other networking for kubernetes.

If you already have prepared hosts you can provide simple ansible inventory (sample is in root of project).


### Run ansible playbooks

Use [Getting started with Ansible](http://docs.ansible.com/ansible/intro_getting_started.html) if you are not familiar with ansible.

Verify that ansible can reach your hosts.

```
ansible -m ping all
```

Validate the global configurations found in `group_vars/all.yml` and update as needed.

To run ansible on hosts you prepared run:

```
ansible-playbook -i inventory setup.yml
```

If you used Terraform to provision your hosts, a plugin is provided that dynamically extracts the inventory from `.tfstate` file.

```
ansible-playbook setup.yml
```

The same plugin can be used to either print out a lists of hosts or to add those hosts to your local `/etc/hosts` file so that you can reference the hosts by name.

The following command will append the hosts to your `/etc/hosts` file.

```
./plugins/inventory/terraform.py --hostfile >> /etc/hosts
```


### Check cluster deployment

#### Validate Control

- Check if all nodes are ready

        kubectl get nodes -o wide

- Check if all Pods, Replication Controllers and Services are running

        kubectl get rc,svc,po --all-namespaces -o wide

- Check status of Kubernetes processes

        sudo systemctl status etcd kube-apiserver kube-controller-manager kube-scheduler -l

- View logs of Kubernetes processes

        sudo journalctl -u etcd
        sudo journalctl -u kube-apiserver
        sudo journalctl -u kube-controller-manager
        sudo journalctl -u kube-scheduler

- Verify DNS working

        # https://github.com/GoogleCloudPlatform/kubernetes/tree/v1.0.1/cluster/addons/dns
        # busybox.yaml
        apiVersion: v1
        kind: Pod
        metadata:
          name: busybox
          namespace: default
        spec:
          containers:
          - image: busybox
            command:
              - sleep
              - "3600"
            imagePullPolicy: IfNotPresent
            name: busybox
          restartPolicy: Always


        kubectl create -f busybox.yaml
        kubectl get pods busybox
        kubectl exec busybox -- nslookup kubernetes

- Verify NAT settings

        sudo iptables -t nat -L -n -v


#### Validate Nodes

- Check status of Kubernetes processes

        sudo systemctl status kubelet kube-proxy flanneld docker -l

- View logs of Kubernetes processes

        sudo journalctl -u kubelet
        sudo journalctl -u kube-proxy
        sudo journalctl -u flanneld
        sudo journalctl -u docker

- Verify NAT settings

        sudo iptables -t nat -L -n -v

