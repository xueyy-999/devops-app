#!/bin/bash
# 一键部署所有Kubernetes资源

set -e

echo "🚀 开始部署Demo应用到Kubernetes..."

# 创建命名空间
echo "📦 创建命名空间..."
kubectl apply -f namespace.yaml

# 部署数据库
echo "🗄️  部署PostgreSQL..."
kubectl apply -f postgres-deployment.yaml

# 部署Redis
echo "💾 部署Redis..."
kubectl apply -f redis-deployment.yaml

# 等待数据库就绪
echo "⏳ 等待数据库就绪..."
kubectl wait --for=condition=ready pod -l app=postgres -n demo-app --timeout=120s

# 等待Redis就绪
echo "⏳ 等待Redis就绪..."
kubectl wait --for=condition=ready pod -l app=redis -n demo-app --timeout=60s

# 部署后端
echo "🔧 部署后端服务..."
kubectl apply -f backend-deployment.yaml

# 等待后端就绪
echo "⏳ 等待后端就绪..."
kubectl wait --for=condition=ready pod -l app=backend -n demo-app --timeout=120s

# 部署前端
echo "🎨 部署前端服务..."
kubectl apply -f frontend-deployment.yaml

# 等待前端就绪
echo "⏳ 等待前端就绪..."
kubectl wait --for=condition=ready pod -l app=frontend -n demo-app --timeout=60s

echo ""
echo "✅ 部署完成！"
echo ""
echo "📋 查看部署状态:"
echo "   kubectl get all -n demo-app"
echo ""
echo "🌐 访问应用:"
echo "   http://localhost:30080"
echo ""
echo "📊 查看日志:"
echo "   kubectl logs -f -l app=backend -n demo-app"
echo "   kubectl logs -f -l app=frontend -n demo-app"
echo ""

