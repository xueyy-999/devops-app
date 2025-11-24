#!/bin/bash
# 云原生DevOps平台 - 完整验证脚本
# 验证所有组件是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 打印函数
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 检查服务是否可访问
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    print_info "检查 $name: $url"
    
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [ "$response" = "$expected_code" ] || [ "$response" = "200" ] || [ "$response" = "302" ]; then
            print_success "$name 可访问 (HTTP $response)"
            return 0
        else
            print_error "$name 不可访问 (HTTP $response)"
            return 1
        fi
    else
        print_error "curl 未安装，无法检查 $name"
        return 1
    fi
}

# 检查Docker容器
check_docker_container() {
    local container_name=$1
    
    if command -v docker &> /dev/null; then
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            status=$(docker inspect --format='{{.State.Status}}' "$container_name")
            if [ "$status" = "running" ]; then
                print_success "容器 $container_name 正在运行"
                return 0
            else
                print_error "容器 $container_name 状态异常: $status"
                return 1
            fi
        else
            print_error "容器 $container_name 未运行"
            return 1
        fi
    else
        print_info "Docker 未安装，跳过容器检查"
        return 0
    fi
}

# 主验证流程
main() {
    print_header "云原生DevOps平台 - 系统验证"
    echo ""
    
    # 1. 检查Docker容器
    print_header "1. 检查Docker容器状态"
    check_docker_container "prometheus"
    check_docker_container "grafana"
    check_docker_container "gitlab"
    check_docker_container "jenkins"
    check_docker_container "registry"
    check_docker_container "postgres"
    check_docker_container "redis"
    echo ""
    
    # 2. 检查监控服务
    print_header "2. 检查监控服务"
    check_service "Prometheus" "http://localhost:9090/-/healthy"
    check_service "Grafana" "http://localhost:3000/api/health"
    echo ""
    
    # 3. 检查CI/CD服务
    print_header "3. 检查CI/CD服务"
    check_service "GitLab" "http://localhost/-/health"
    check_service "Jenkins" "http://localhost:8080/login"
    check_service "Registry" "http://localhost:5000/v2/"
    echo ""
    
    # 4. 检查数据库服务
    print_header "4. 检查数据库服务"
    if command -v docker &> /dev/null; then
        if docker exec postgres pg_isready -U gitlab &> /dev/null; then
            print_success "PostgreSQL 数据库正常"
        else
            print_error "PostgreSQL 数据库异常"
        fi
        
        if docker exec redis redis-cli ping | grep -q "PONG"; then
            print_success "Redis 缓存正常"
        else
            print_error "Redis 缓存异常"
        fi
    fi
    echo ""
    
    # 5. 检查示例应用
    print_header "5. 检查示例应用"
    check_service "Demo Frontend" "http://localhost:8888"
    check_service "Demo Backend" "http://localhost:5001/health"
    echo ""
    
    # 6. 生成报告
    print_header "验证报告"
    echo -e "总检查项: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo ""
        print_success "所有检查通过！平台运行正常 🎉"
        exit 0
    else
        echo ""
        print_error "部分检查失败，请查看上述错误信息"
        exit 1
    fi
}

# 运行主函数
main

