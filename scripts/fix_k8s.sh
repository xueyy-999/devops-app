#!/bin/bash

echo "🔧 Diagnosing and Fixing Kubernetes Control Plane..."

# 1. Disable Swap (Critical for Kubelet)
echo "1. Disabling Swap..."
swapoff -a
# Ensure it stays off (comment out validation if strictly needed, but this is a quick fix)
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Check and Restart Kubelet
echo "2. Restarting Kubelet..."
systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet

# 3. Wait for Kubelet to initialize
echo "⏳ Waiting 15s for Kubelet to start..."
sleep 15

# 4. Check Kubelet Status
if systemctl is-active --quiet kubelet; then
    echo "✅ Kubelet is running."
else
    echo "❌ Kubelet failed to start. Logs:"
    journalctl -u kubelet -n 20 --no-pager
    exit 1
fi

# 5. Check API Server Container (via crictl or docker)
echo "5. Checking API Server container status..."
if command -v crictl &> /dev/null; then
    crictl ps -a | grep kube-apiserver
elif command -v docker &> /dev/null; then
    docker ps -a | grep kube-apiserver
fi

# 6. Verify Cluster Access
echo "6. Verifying kubectl access..."
for i in {1..10}; do
    if kubectl get nodes &> /dev/null; then
        echo "✅ Kubernetes API is available!"
        kubectl get nodes
        kubectl get pods -A | grep -v "Running"
        exit 0
    fi
    echo "   Thinking... (attempt $i/10)"
    sleep 5
done

echo "❌ Kubernetes API is still unreachable. Please check logs manually."
journalctl -u kubelet -n 50 --no-pager
