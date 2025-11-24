#!/bin/bash
# CI/CD流水线测试脚本
# 测试完整的CI/CD流程

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CI/CD流水线完整测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 检查Docker环境
print_step "1. 检查Docker环境"
if ! command -v docker &> /dev/null; then
    print_error "Docker未安装"
    exit 1
fi
print_success "Docker已安装"

# 2. 构建示例应用镜像
print_step "2. 构建示例应用镜像"
cd demo-app

print_info "构建后端镜像..."
cd backend
docker build -t localhost:5000/demo-backend:test .
print_success "后端镜像构建成功"

cd ..
print_info "构建前端镜像..."
cd frontend
docker build -t localhost:5000/demo-frontend:test .
print_success "前端镜像构建成功"

cd ../..

# 3. 测试镜像
print_step "3. 测试镜像"
print_info "测试后端镜像..."
docker run --rm -d --name test-backend \
    -e DB_HOST=localhost \
    -e REDIS_HOST=localhost \
    -p 5555:5000 \
    localhost:5000/demo-backend:test

sleep 5

if curl -f http://localhost:5555/ &> /dev/null; then
    print_success "后端镜像测试通过"
else
    print_error "后端镜像测试失败"
fi

docker stop test-backend &> /dev/null || true

print_info "测试前端镜像..."
docker run --rm -d --name test-frontend \
    -p 8889:80 \
    localhost:5000/demo-frontend:test

sleep 3

if curl -f http://localhost:8889/ &> /dev/null; then
    print_success "前端镜像测试通过"
else
    print_error "前端镜像测试失败"
fi

docker stop test-frontend &> /dev/null || true

# 4. 推送镜像到Registry（如果Registry运行中）
print_step "4. 推送镜像到Registry"
if curl -f http://localhost:5000/v2/ &> /dev/null; then
    print_info "推送后端镜像..."
    docker push localhost:5000/demo-backend:test
    print_success "后端镜像推送成功"
    
    print_info "推送前端镜像..."
    docker push localhost:5000/demo-frontend:test
    print_success "前端镜像推送成功"
    
    # 验证镜像已推送
    print_info "验证镜像..."
    if curl -f http://localhost:5000/v2/demo-backend/tags/list &> /dev/null; then
        print_success "后端镜像已在Registry中"
    fi
    
    if curl -f http://localhost:5000/v2/demo-frontend/tags/list &> /dev/null; then
        print_success "前端镜像已在Registry中"
    fi
else
    print_info "Registry未运行，跳过推送步骤"
fi

# 5. 测试完整应用栈
print_step "5. 测试完整应用栈"
print_info "启动完整应用..."
cd demo-app
docker-compose up -d

print_info "等待服务启动..."
sleep 30

# 检查服务健康状态
if curl -f http://localhost:5001/health &> /dev/null; then
    print_success "后端服务健康检查通过"
else
    print_error "后端服务健康检查失败"
fi

if curl -f http://localhost:8888/ &> /dev/null; then
    print_success "前端服务可访问"
else
    print_error "前端服务不可访问"
fi

# 测试API功能
print_info "测试API功能..."
response=$(curl -s -X POST http://localhost:5001/api/messages \
    -H "Content-Type: application/json" \
    -d '{"author":"CI/CD测试","content":"自动化测试消息"}')

if echo "$response" | grep -q "消息创建成功"; then
    print_success "API功能测试通过"
else
    print_error "API功能测试失败"
fi

# 清理
print_step "6. 清理测试环境"
docker-compose down
cd ..

print_success "测试环境已清理"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ CI/CD流水线测试完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "测试总结:"
echo "  ✅ Docker环境检查"
echo "  ✅ 镜像构建"
echo "  ✅ 镜像测试"
echo "  ✅ Registry推送"
echo "  ✅ 应用栈测试"
echo "  ✅ API功能测试"
echo ""

