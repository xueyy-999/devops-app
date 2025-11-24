#!/bin/bash
# Check status of all DevOps services

echo "========================================"
echo "   DevOps Platform Status Check"
echo "========================================"

# 1. Check Systemd Services
echo -e "\n[System Services]"
for service in docker postgresql redis nginx jenkins kubelet; do
    status=$(systemctl is-active $service)
    if [ "$status" == "active" ]; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: $status"
    fi
done

# 2. Check GitLab (Omnibus)
echo -e "\n[GitLab]"
if command -v gitlab-ctl &> /dev/null; then
    gitlab_status=$(gitlab-ctl status | grep "run:" | wc -l)
    if [ $gitlab_status -gt 0 ]; then
        echo "✅ GitLab: Running ($gitlab_status components)"
    else
        echo "❌ GitLab: Not running"
    fi
else
    echo "❌ GitLab: Not installed (gitlab-ctl not found)"
fi

# 3. Check Harbor (Docker Compose)
echo -e "\n[Harbor]"
if [ -d "/opt/harbor" ]; then
    cd /opt/harbor
    if docker compose ps | grep "Up" > /dev/null; then
        echo "✅ Harbor: Running"
    else
        echo "❌ Harbor: Not running"
    fi
else
    echo "❌ Harbor: Directory /opt/harbor not found"
fi

# 4. Check Monitoring (Docker Containers)
echo -e "\n[Monitoring]"
for container in prometheus grafana; do
    if docker ps | grep -q $container; then
        echo "✅ $container: Running"
    else
        echo "❌ $container: Not running"
    fi
done

# 5. Check Ports
echo -e "\n[Port Check]"
check_port() {
    if nc -z localhost $1 2>/dev/null; then
        echo "✅ Port $1 ($2): Open"
    else
        echo "❌ Port $1 ($2): Closed"
    fi
}

check_port 80 "GitLab/Nginx"
check_port 8080 "Jenkins"
check_port 5000 "Harbor"
check_port 9090 "Prometheus"
check_port 3000 "Grafana"

echo -e "\n========================================"
