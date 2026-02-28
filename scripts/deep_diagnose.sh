#!/bin/bash
echo "🔍 ----------------- Deep Diagnosis (Low Level) -----------------"

# Function to get logs via crictl (bypasses API server)
get_container_logs() {
    NAME=$1
    echo ">> Checking logs for $NAME (via crictl)..."
    # Get the latest container ID (Running or Exited)
    ID=$(crictl ps -a --name $NAME -q | head -n 1)
    
    if [ -z "$ID" ]; then
        echo "   No container found for $NAME"
    else
        echo "   Container ID: $ID"
        echo "   Logs:"
        crictl logs $ID --tail=20
    fi
    echo "------------------------------------------------------------"
}

# 1. 检查 API Server (最核心)
get_container_logs "kube-apiserver"

# 2. 检查 Scheduler 和 Controller
get_container_logs "kube-scheduler"
get_container_logs "kube-controller-manager"

# 3. 检查 Kubelet 关于 API Server 的报错
echo ">> Checking Kubelet logs for API Server errors..."
journalctl -u kubelet --no-pager | grep -i "apiserver" | tail -n 10
