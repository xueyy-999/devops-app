#!/bin/bash
# Cloud Native DevOps Platform - One-Click Start Script
# Run this script in the project root directory: [xue@xyy cloud-native-devops-platform]$

echo "========================================"
echo "   Starting DevOps Platform..."
echo "========================================"

# 1. Check Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible not found. Installing..."
    chmod +x install-ansible.sh
    ./install-ansible.sh
fi

# 2. Start Services using Ansible
echo -e "\n🚀 Starting services using Ansible..."
# We use the verification playbook to ensure everything is up, 
# or run specific setup playbooks if needed.
# But since you said it's already deployed, we'll try to ensure services are started.

# Option A: Run the full site.yml (might be slow if it re-checks everything)
# ansible-playbook -i inventory/single-node.yml site.yml

# Option B: Just start the services directly (Faster)
echo "Starting Systemd services..."
sudo systemctl start docker postgresql redis nginx jenkins kubelet

echo "Starting GitLab..."
sudo gitlab-ctl start

echo "Starting Harbor..."
if [ -d "/opt/harbor" ]; then
    cd /opt/harbor && sudo docker compose up -d
fi

echo "Starting Monitoring..."
sudo docker start prometheus grafana || true

# 3. Verify Status
echo -e "\n🔍 Verifying status..."
if [ -f "scripts/health-check.sh" ]; then
    bash scripts/health-check.sh
else
    echo "Health check script not found, checking manually..."
    sudo netstat -tuln | grep -E ":80|:443|:8080|:5000|:9090|:3000"
fi

echo -e "\n✅ Done! Access services at:"
echo "   GitLab:     http://$(hostname -I | awk '{print $1}')"
echo "   Jenkins:    http://$(hostname -I | awk '{print $1}'):8080"
echo "   Harbor:     http://$(hostname -I | awk '{print $1}'):5000"
echo "   Grafana:    http://$(hostname -I | awk '{print $1}'):3000"
