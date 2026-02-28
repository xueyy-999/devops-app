#!/bin/bash
echo "🔍 正在诊断 Kubernetes 组件崩溃问题..."

# 1.获取崩溃的 Pod 列表
PODS=$(kubectl get pods -n kube-system | grep CrashLoopBackOff | awk '{print $1}')

if [ -z "$PODS" ]; then
    echo "✅ 没有发现 CrashLoopBackOff 状态的 Pod。"
else
    echo "⚠️ 发现以下 Pod 崩溃："
    echo "$PODS"
fi

# 2. 抓取日志函数
check_log() {
    POD_NAME=$1
    echo ""
    echo "========================================================"
    echo "📋 正在查看 Pod 日志: $POD_NAME"
    echo "========================================================"
    
    # 尝试用 kubectl 获取最后 50 行日志
    kubectl logs -n kube-system $POD_NAME --tail=50
    
    # 如果 kubectl 没抓到 (比如容器启动瞬间挂掉), 尝试用 crictl (底层容器运行时)
    echo ""
    echo "--- (尝试底层容器日志) ---"
    # 获取该 Pod 对应的容器 ID (模糊匹配)
    #由于Pod名包含guid，我们需要匹配前缀
    PREFIX=$(echo $POD_NAME | cut -d'-' -f 1-2) 
    CONTAINER_ID=$(crictl ps -a --name $PREFIX -q | head -n 1)
    
    if [ ! -z "$CONTAINER_ID" ]; then
        crictl logs $CONTAINER_ID --tail=20
    else
        echo "未能找到对应的底层容器 ID"
    fi
}

# 3. 循环检查详细日志
for POD in $PODS; do
    check_log $POD
done

# 4. 检查 kube-proxy (如果是 DaemonSet 方式)
echo ""
echo "检查 kube-proxy 配置..."
kubectl -n kube-system describe configmap kube-proxy
