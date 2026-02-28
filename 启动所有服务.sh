#!/bin/bash
# Start all services on CentOS 9
# Run this if services are already installed but stopped

echo "Starting all services..."

# 1. Start Base Services
echo "Starting PostgreSQL..."
sudo systemctl start postgresql
echo "Starting Redis..."
sudo systemctl start redis
echo "Starting Nginx..."
sudo systemctl start nginx

# 2. Start Jenkins
echo "Starting Jenkins..."
sudo systemctl start jenkins

# 3. Start GitLab
echo "Starting GitLab..."
sudo gitlab-ctl start

# 4. Start Harbor
echo "Starting Harbor..."
if [ -d "/opt/harbor" ]; then
    cd /opt/harbor
    if command -v docker &> /dev/null && sudo systemctl is-active docker >/dev/null 2>&1; then
        sudo docker compose up -d
    else
        echo "Docker 未运行，跳过 Harbor(基于 docker compose)"
    fi
else
    echo "Harbor directory not found, skipping."
fi

# 5. Start Monitoring (Prometheus/Grafana)
# Assuming they are running as Docker containers or K8s pods
# If Docker containers:
echo "Starting Monitoring Containers..."
if command -v docker &> /dev/null && sudo systemctl is-active docker >/dev/null 2>&1; then
    sudo docker start prometheus grafana || true
else
    echo "Docker 未运行，跳过 Monitoring Containers"
fi

# 6. Ensure Kubernetes is running
echo "🔧 Checking and Fixing Kubernetes Control Plane..."
# Disable swap (Critical for Kubelet)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Ensure containerd is running
echo "Starting containerd..."
sudo systemctl enable containerd >/dev/null 2>&1 || true
sudo systemctl restart containerd

# Ensure Kubelet is running
echo "Restarting Kubelet..."
sudo systemctl enable kubelet
sudo systemctl restart kubelet

echo "⏳ Waiting for Kubernetes API to be ready..."
for i in {1..30}; do
    if sudo kubectl get nodes &> /dev/null; then
        echo "✅ Kubernetes API is available!"
        sudo kubectl get nodes
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
if ! sudo kubectl get nodes &> /dev/null; then
    echo "⚠️ Kubernetes API is still not reachable. Checking kubelet logs..."
    sudo journalctl -u kubelet -n 20 --no-pager
fi

echo ""
echo "=== Running Health Check ==="
if [ -f "scripts/health-check.sh" ]; then
    sudo bash scripts/health-check.sh
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "❌ Health check failed (exit=$rc)"
        exit "$rc"
    fi
else
    echo "Health check script not found: scripts/health-check.sh"
    exit 1
fi

echo "=== All Services Started ==="
