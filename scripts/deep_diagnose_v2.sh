#!/bin/bash
echo "🔍 ----------------- 深度诊断 V2 (直接读取日志文件) -----------------"

# 1. 直接去找日志文件 (绕过 crictl 语法问题)
echo ">> 尝试直接读取 API Server 日志文件:"
# 通常 K8s 静态 Pod 日志路径
LOG_FILES=$(find /var/log/pods -name "*kube-apiserver*" -type f -name "*.log")

if [ -z "$LOG_FILES" ]; then
    echo "❌ 未找到 /var/log/pods 下的 API Server 日志"
    # 尝试找 containers 目录
    ls -l /var/log/containers/*kube-apiserver* 2>/dev/null
else
    # 只看最新的一个日志文件
    LATEST_LOG=$(ls -t $LOG_FILES | head -n 1)
    echo "Found log file: $LATEST_LOG"
    echo "--- Last 50 lines ---"
    tail -n 50 "$LATEST_LOG"
    echo "---------------------"
fi

# 2. 再次尝试简单的 crictl logs (不带参数)
echo ""
echo ">> 再次尝试 crictl logs (尝试不同语法):"
CONTAINER_ID=$(crictl ps -a --name kube-apiserver -q | head -n 1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Container ID: $CONTAINER_ID"
    # 尝试两种常见语法
    crictl logs "$CONTAINER_ID" 2>/dev/null | tail -n 20 || crictl logs --tail=20 "$CONTAINER_ID"
fi

# 3. 检查 Controller Manager 日志 (它也在崩溃)
echo ""
echo ">> 尝试直接读取 Controller Manager 日志文件:"
LOG_FILES_CM=$(find /var/log/pods -name "*kube-controller-manager*" -type f -name "*.log")
if [ ! -z "$LOG_FILES_CM" ]; then
    LATEST_LOG_CM=$(ls -t $LOG_FILES_CM | head -n 1)
    echo "Found log file: $LATEST_LOG_CM"
    tail -n 20 "$LATEST_LOG_CM"
fi

# 4. 检查证书有效期 (常见问题)
echo ""
echo ">> 检查证书有效期:"
if [ -f /etc/kubernetes/pki/apiserver.crt ]; then
    openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate
else
    echo "apiserver.crt 不存在"
fi
