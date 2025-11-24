#!/bin/bash

# 1. 停止防火墙 (简单粗暴，确保能访问)
echo "正在关闭防火墙..."
systemctl stop firewalld
systemctl disable firewalld

# 或者，如果你想保留防火墙，请注释上面两行，使用下面的命令开放端口：
# firewall-cmd --zone=public --add-port=80/tcp --permanent
# firewall-cmd --zone=public --add-port=8080/tcp --permanent
# firewall-cmd --zone=public --add-port=5000/tcp --permanent
# firewall-cmd --zone=public --add-port=3000/tcp --permanent
# firewall-cmd --zone=public --add-port=9090/tcp --permanent
# firewall-cmd --reload

# 2. 启动 Jenkins
echo "正在启动 Jenkins..."
systemctl start jenkins

# 3. 启动 Harbor
echo "正在启动 Harbor..."
if [ -d "/opt/harbor" ]; then
    cd /opt/harbor
    docker compose down
    docker compose up -d
else
    echo "找不到 /opt/harbor 目录"
fi

# 4. 启动 Prometheus 和 Grafana
echo "正在启动监控组件..."
docker start prometheus grafana node-exporter || true

# 5. 检查状态
echo "--------------------------------"
echo "服务状态检查："
echo "--------------------------------"
netstat -tuln | grep -E '8080|5000|3000|9090'
echo "--------------------------------"
echo "如果看到上面有 8080, 5000, 3000, 9090 端口，说明启动成功！"
