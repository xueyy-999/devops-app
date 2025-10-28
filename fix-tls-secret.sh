#!/bin/bash

# 清理TLS secret脚本
echo "清理现有的TLS secret..."

# 删除现有的web-app-tls secret
kubectl delete secret web-app-tls -n production --ignore-not-found=true

# 删除现有的web-app-secret
kubectl delete secret web-app-secret -n production --ignore-not-found=true

echo "TLS secret清理完成"
