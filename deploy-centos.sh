#!/bin/bash
# CentOS 9 Stream - Full Deployment Script
# Run this script on your CentOS VM

set -e

echo "=== Cloud Native DevOps Platform Deployment ==="

# 1. Install Ansible
echo "[Step 1] Installing Ansible..."
chmod +x install-ansible.sh
./install-ansible.sh

# 2. Configure Inventory
echo "[Step 2] Configuring Inventory..."
if [ ! -f inventory/single-node.yml ]; then
    cp inventory/single-node.yml.example inventory/single-node.yml
    echo "Created inventory/single-node.yml"
    echo "⚠️  IMPORTANT: Please edit inventory/single-node.yml and set your IP address!"
    echo "   Use 'vim inventory/single-node.yml' to edit."
    read -p "Press Enter after you have edited the inventory file..."
fi

# 3. Run Playbooks
echo "[Step 3] Running Playbooks..."

echo ">> 01-common-setup.yml"
ansible-playbook -i inventory/single-node.yml playbooks/01-common-setup.yml

echo ">> 02-docker-setup.yml"
ansible-playbook -i inventory/single-node.yml playbooks/02-docker-setup.yml

echo ">> 03-kubernetes-fixed.yml"
ansible-playbook -i inventory/single-node.yml playbooks/03-kubernetes-fixed.yml

echo ">> 04-monitoring-setup.yml"
ansible-playbook -i inventory/single-node.yml playbooks/04-monitoring-setup.yml

echo ">> 05-cicd-setup.yml"
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml

echo ">> 06-application-deploy.yml"
ansible-playbook -i inventory/single-node.yml playbooks/06-application-deploy.yml

echo ">> 07-verification.yml"
ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml

echo "=== Deployment Complete! ==="
