#!/bin/bash

# 单节点云原生DevOps平台部署脚本
# 适用于单机测试环境

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
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 命令未找到，请先安装"
        exit 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        log_error "文件 $1 不存在"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
单节点云原生DevOps平台部署脚本

用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    -i, --inventory FILE    指定inventory文件 (默认: inventory/single-node.yml)
    -t, --tags TAGS         指定要执行的标签
    -s, --skip-verify       跳过验证步骤
    -v, --verbose           详细输出
    --check                 检查模式，不执行实际部署
    --list-tags             列出所有可用标签

示例:
    $0                      # 完整部署
    $0 --tags setup,common  # 只执行基础配置
    $0 --check              # 检查模式
    $0 --list-tags          # 列出所有标签

EOF
}

# 默认参数
INVENTORY="inventory/single-node.yml"
TAGS=""
SKIP_VERIFY=false
VERBOSE=false
CHECK_MODE=false
LIST_TAGS=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -t|--tags)
            TAGS="$2"
            shift 2
            ;;
        -s|--skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --check)
            CHECK_MODE=true
            shift
            ;;
        --list-tags)
            LIST_TAGS=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查必要命令
log_info "检查必要命令..."
check_command ansible
check_command ansible-playbook

# 检查必要文件
log_info "检查必要文件..."
check_file "$INVENTORY"
check_file "site.yml"
check_file "ansible.cfg"

# 构建ansible-playbook命令
ANSIBLE_CMD="ansible-playbook -i $INVENTORY"

if [ "$VERBOSE" = true ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -v"
fi

if [ -n "$TAGS" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --tags $TAGS"
fi

if [ "$SKIP_VERIFY" = true ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e skip_verification=true"
fi

if [ "$CHECK_MODE" = true ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --check"
fi

# 设置部署模式为单节点
ANSIBLE_CMD="$ANSIBLE_CMD -e deployment_mode=single"

# 特殊处理
if [ "$LIST_TAGS" = true ]; then
    log_info "列出所有可用标签..."
    ansible-playbook -i "$INVENTORY" --list-tags site.yml
    exit 0
fi

# 显示部署信息
log_info "=== 单节点云原生DevOps平台部署 ==="
log_info "Inventory文件: $INVENTORY"
log_info "标签: ${TAGS:-'all'}"
log_info "跳过验证: $SKIP_VERIFY"
log_info "详细输出: $VERBOSE"
log_info "检查模式: $CHECK_MODE"
log_info "================================"

# 确认部署
if [ "$CHECK_MODE" = false ]; then
    read -p "确认开始部署? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
fi

# 执行部署
log_info "开始部署..."
if [ "$CHECK_MODE" = true ]; then
    log_info "检查模式，不会执行实际部署"
fi

# 执行ansible-playbook
if $ANSIBLE_CMD site.yml; then
    log_success "部署完成！"
    
    if [ "$CHECK_MODE" = false ]; then
        log_info "=== 部署后操作 ==="
        log_info "1. 检查服务状态: systemctl status <service-name>"
        log_info "2. 查看日志: journalctl -u <service-name> -f"
        log_info "3. 访问应用: http://192.168.76.141"
        log_info "4. 访问监控: http://192.168.76.141:9090"
        log_info "5. 访问仪表板: http://192.168.76.141:3000"
        log_info "6. 访问GitLab: http://192.168.76.141"
        log_info "7. 访问Jenkins: http://192.168.76.141:8080"
        log_info "8. 访问Harbor: http://192.168.76.141"
        log_info ""
        log_info "=== 验证命令 ==="
        log_info "kubectl get nodes"
        log_info "kubectl get pods --all-namespaces"
        log_info "systemctl status docker"
        log_info "systemctl status kubelet"
    fi
else
    log_error "部署失败！"
    exit 1
fi
