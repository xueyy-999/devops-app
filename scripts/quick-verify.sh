#!/bin/bash

# 快速验证脚本 - 检查单节点部署状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查函数
check_service() {
    local service_name=$1
    local service_status=$(systemctl is-active $service_name 2>/dev/null || echo "inactive")
    
    if [ "$service_status" = "active" ]; then
        log_success "$service_name 服务运行正常"
        return 0
    else
        log_error "$service_name 服务未运行"
        return 1
    fi
}

check_port() {
    local port=$1
    local service_name=$2
    
    if nc -z localhost $port 2>/dev/null; then
        log_success "$service_name 端口 $port 可访问"
        return 0
    else
        log_error "$service_name 端口 $port 不可访问"
        return 1
    fi
}

check_kubernetes() {
    local component=$1
    
    case $component in
        "nodes")
            if kubectl get nodes >/dev/null 2>&1; then
                local ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
                local total_nodes=$(kubectl get nodes --no-headers | wc -l)
                log_success "Kubernetes节点: $ready_nodes/$total_nodes 就绪"
                return 0
            else
                log_error "无法连接到Kubernetes集群"
                return 1
            fi
            ;;
        "pods")
            if kubectl get pods --all-namespaces >/dev/null 2>&1; then
                local running_pods=$(kubectl get pods --all-namespaces --no-headers | grep -c "Running")
                local total_pods=$(kubectl get pods --all-namespaces --no-headers | wc -l)
                log_success "Kubernetes Pod: $running_pods/$total_pods 运行中"
                return 0
            else
                log_error "无法获取Kubernetes Pod状态"
                return 1
            fi
            ;;
    esac
}

# 主检查函数
main() {
    log_info "开始快速验证单节点部署..."
    echo "========================================"
    
    # 检查系统基础服务
    log_info "检查系统基础服务..."
    check_service "chronyd"
    check_service "firewalld"
    echo ""
    
    # 检查Docker服务
    log_info "检查Docker服务..."
    check_service "docker"
    check_service "containerd"
    echo ""
    
    # 检查Kubernetes服务
    log_info "检查Kubernetes服务..."
    check_service "kubelet"
    check_kubernetes "nodes"
    check_kubernetes "pods"
    echo ""
    
    # 检查监控服务
    log_info "检查监控服务..."
    check_service "prometheus"
    check_service "grafana-server"
    check_service "alertmanager"
    check_service "node_exporter"
    
    # 检查监控端口
    check_port "9090" "Prometheus"
    check_port "3000" "Grafana"
    check_port "9093" "Alertmanager"
    check_port "9100" "Node Exporter"
    echo ""
    
    # 检查CI/CD服务
    log_info "检查CI/CD服务..."
    check_service "gitlab"
    check_service "jenkins"
    check_service "harbor"
    
    # 检查CI/CD端口
    check_port "80" "GitLab"
    check_port "8080" "Jenkins"
    check_port "80" "Harbor"
    echo ""
    
    # 检查应用服务
    log_info "检查应用服务..."
    check_kubernetes "pods"
    
    # 检查应用Pod
    if kubectl get pods -n production -l app=web-app >/dev/null 2>&1; then
        local app_pods=$(kubectl get pods -n production -l app=web-app --no-headers | grep -c "Running")
        local total_app_pods=$(kubectl get pods -n production -l app=web-app --no-headers | wc -l)
        log_success "应用Pod: $app_pods/$total_app_pods 运行中"
    else
        log_error "无法获取应用Pod状态"
    fi
    echo ""
    
    # 检查系统资源
    log_info "检查系统资源..."
    
    # 检查CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    if (( $(echo "$cpu_usage < 80" | bc -l) )); then
        log_success "CPU使用率: ${cpu_usage}% (正常)"
    else
        log_warning "CPU使用率: ${cpu_usage}% (较高)"
    fi
    
    # 检查内存使用率
    local memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    if (( $(echo "$memory_usage < 80" | bc -l) )); then
        log_success "内存使用率: ${memory_usage}% (正常)"
    else
        log_warning "内存使用率: ${memory_usage}% (较高)"
    fi
    
    # 检查磁盘使用率
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        log_success "磁盘使用率: ${disk_usage}% (正常)"
    else
        log_warning "磁盘使用率: ${disk_usage}% (较高)"
    fi
    echo ""
    
    # 显示访问信息
    log_info "=== 访问信息 ==="
    log_info "应用地址: http://192.168.76.141"
    log_info "监控地址: http://192.168.76.141:9090"
    log_info "仪表板: http://192.168.76.141:3000"
    log_info "GitLab: http://192.168.76.141"
    log_info "Jenkins: http://192.168.76.141:8080"
    log_info "Harbor: http://192.168.76.141"
    echo ""
    
    # 显示常用命令
    log_info "=== 常用命令 ==="
    log_info "查看节点: kubectl get nodes"
    log_info "查看Pod: kubectl get pods --all-namespaces"
    log_info "查看服务: kubectl get services --all-namespaces"
    log_info "查看应用: kubectl get pods -n production -l app=web-app"
    log_info "查看日志: kubectl logs -n production -l app=web-app -f"
    echo ""
    
    log_success "快速验证完成！"
    echo "========================================"
}

# 执行主函数
main "$@"
