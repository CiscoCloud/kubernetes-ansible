#!/bin/bash
set -e

SSH_KEY=${SSH_KEY:-"/root/.ssh/id_rsa"}

if [ ! -f "$SSH_KEY" ]; then
    mkdir -p /root/.ssh/
    find /ssh/* ! -type l -print0 | xargs -0 cp -t /root/.ssh/
fi
chown root:root /root/.ssh/*

eval `ssh-agent -s` && ssh-add $SSH_KEY

ansible-playbook playbooks/gen_lb_members.yml
terraform get $TERRAFORM_STATE_ROOT
terraform apply -state=$TERRAFORM_STATE_ROOT/terraform.tfstate -input=false $TERRAFORM_STATE_ROOT
ansible-playbook playbooks/wait-for-hosts.yml --private-key $SSH_KEY
ansible-playbook setup.yml --private-key $SSH_KEY
