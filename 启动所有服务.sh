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
    sudo docker compose up -d
else
    echo "Harbor directory not found, skipping."
fi

# 5. Start Monitoring (Prometheus/Grafana)
# Assuming they are running as Docker containers or K8s pods
# If Docker containers:
echo "Starting Monitoring Containers..."
sudo docker start prometheus grafana || true

echo "=== All Services Started ==="
echo "Please check status with: sudo bash scripts/health-check.sh"
