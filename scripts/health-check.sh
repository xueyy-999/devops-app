#!/bin/bash

# 云原生DevOps平台健康检查脚本
# 用于检查系统各个组件的健康状态

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
    local service_status=$(systemctl is-active $service_name)
    
    if [ "$service_status" = "active" ]; then
        log_success "$service_name 服务运行正常"
        return 0
    else
        log_error "$service_name 服务未运行"
        return 1
    fi
}

check_port() {
    local host=$1
    local port=$2
    local service_name=$3
    
    if nc -z $host $port 2>/dev/null; then
        log_success "$service_name 端口 $port 可访问"
        return 0
    else
        log_error "$service_name 端口 $port 不可访问"
        return 1
    fi
}

check_http() {
    local url=$1
    local service_name=$2
    
    if curl -s -f $url >/dev/null 2>&1; then
        log_success "$service_name HTTP服务可访问"
        return 0
    else
        log_error "$service_name HTTP服务不可访问"
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
        "services")
            if kubectl get services --all-namespaces >/dev/null 2>&1; then
                local total_services=$(kubectl get services --all-namespaces --no-headers | wc -l)
                log_success "Kubernetes服务: $total_services 个服务"
                return 0
            else
                log_error "无法获取Kubernetes服务状态"
                return 1
            fi
            ;;
    esac
}

# 主检查函数
main() {
    log_info "开始云原生DevOps平台健康检查..."
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
    check_kubernetes "services"
    echo ""
    
    # 检查监控服务
    log_info "检查监控服务..."
    check_service "prometheus"
    check_service "grafana-server"
    check_service "alertmanager"
    check_service "node_exporter"
    
    # 检查监控端口
    check_port "localhost" "9090" "Prometheus"
    check_port "localhost" "3000" "Grafana"
    check_port "localhost" "9093" "Alertmanager"
    check_port "localhost" "9100" "Node Exporter"
    
    # 检查监控HTTP服务
    check_http "http://localhost:9090/api/v1/query?query=up" "Prometheus"
    check_http "http://localhost:3000/api/health" "Grafana"
    check_http "http://localhost:9093/api/v1/status" "Alertmanager"
    echo ""
    
    # 检查CI/CD服务
    log_info "检查CI/CD服务..."
    check_service "gitlab"
    check_service "jenkins"
    check_service "harbor"
    
    # 检查CI/CD端口
    check_port "localhost" "80" "GitLab"
    check_port "localhost" "8080" "Jenkins"
    check_port "localhost" "80" "Harbor"
    
    # 检查CI/CD HTTP服务
    check_http "http://localhost/api/v4/version" "GitLab"
    check_http "http://localhost:8080/api/json" "Jenkins"
    check_http "http://localhost/api/v2.0/systeminfo" "Harbor"
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
    
    # 检查应用服务
    if kubectl get services -n production -l app=web-app >/dev/null 2>&1; then
        local app_services=$(kubectl get services -n production -l app=web-app --no-headers | wc -l)
        log_success "应用服务: $app_services 个服务"
    else
        log_error "无法获取应用服务状态"
    fi
    
    # 检查应用Ingress
    if kubectl get ingress -n production -l app=web-app >/dev/null 2>&1; then
        local app_ingress=$(kubectl get ingress -n production -l app=web-app --no-headers | wc -l)
        log_success "应用Ingress: $app_ingress 个入口"
    else
        log_error "无法获取应用Ingress状态"
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
    
    # 检查网络连接
    log_info "检查网络连接..."
    
    # 检查DNS解析
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS解析正常"
    else
        log_error "DNS解析失败"
    fi
    
    # 检查网络连通性
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "网络连通性正常"
    else
        log_error "网络连通性异常"
    fi
    echo ""
    
    # 生成健康检查报告
    log_info "生成健康检查报告..."
    cat > /tmp/health-check-report.md << EOF
# 云原生DevOps平台健康检查报告

## 检查时间
$(date)

## 系统信息
- 主机名: $(hostname)
- 操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- 内核版本: $(uname -r)
- 系统负载: $(uptime | awk -F'load average:' '{print $2}')

## 服务状态
- Docker: $(systemctl is-active docker)
- Kubernetes: $(systemctl is-active kubelet)
- Prometheus: $(systemctl is-active prometheus)
- Grafana: $(systemctl is-active grafana-server)
- Alertmanager: $(systemctl is-active alertmanager)
- GitLab: $(systemctl is-active gitlab)
- Jenkins: $(systemctl is-active jenkins)
- Harbor: $(systemctl is-active harbor)

## 资源使用情况
- CPU使用率: ${cpu_usage}%
- 内存使用率: ${memory_usage}%
- 磁盘使用率: ${disk_usage}%

## 网络状态
- DNS解析: $(nslookup google.com >/dev/null 2>&1 && echo "正常" || echo "异常")
- 网络连通性: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "正常" || echo "异常")

## 建议
1. 定期检查系统资源使用情况
2. 监控服务状态和日志
3. 定期备份重要数据
4. 更新系统和软件包
EOF
    
    log_success "健康检查完成！"
    log_info "报告已保存到: /tmp/health-check-report.md"
    echo "========================================"
}

# 执行主函数
main "$@"
