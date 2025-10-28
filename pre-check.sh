#!/bin/bash

# 部署前环境检查脚本
# 用于检查系统是否满足部署要求

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查结果统计
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查系统信息
check_system_info() {
    log_section "系统信息检查"
    
    # 操作系统
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        log_info "操作系统: $NAME $VERSION"
        
        if [[ "$ID" == "centos" || "$ID" == "rocky" || "$ID" == "rhel" ]]; then
            if [[ "$VERSION_ID" == "9" || "$VERSION_ID" =~ ^9\. ]]; then
                log_pass "操作系统版本符合要求 (CentOS/Rocky/RHEL 9)"
            else
                log_fail "操作系统版本不符合要求，建议使用 CentOS/Rocky Linux 9"
            fi
        else
            log_warn "未检测到 CentOS/Rocky Linux，可能遇到兼容性问题"
        fi
    else
        log_fail "无法检测操作系统信息"
    fi
    
    # 内核版本
    KERNEL_VERSION=$(uname -r)
    log_info "内核版本: $KERNEL_VERSION"
}

# 检查硬件资源
check_hardware() {
    log_section "硬件资源检查"
    
    # CPU核心数
    CPU_CORES=$(nproc)
    log_info "CPU核心数: $CPU_CORES"
    if [ $CPU_CORES -ge 4 ]; then
        log_pass "CPU核心数满足最低要求 (>= 4核)"
    elif [ $CPU_CORES -ge 2 ]; then
        log_warn "CPU核心数为 $CPU_CORES，建议至少4核"
    else
        log_fail "CPU核心数不足，最低需要2核，建议4核以上"
    fi
    
    # 内存大小
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    log_info "总内存: ${TOTAL_MEM}GB"
    if [ $TOTAL_MEM -ge 16 ]; then
        log_pass "内存充足 (>= 16GB)"
    elif [ $TOTAL_MEM -ge 8 ]; then
        log_warn "内存为 ${TOTAL_MEM}GB，建议16GB以上"
    else
        log_fail "内存不足，最低需要8GB，建议16GB以上"
    fi
    
    # 磁盘空间
    ROOT_DISK=$(df -h / | awk 'NR==2 {print $4}')
    log_info "根分区可用空间: $ROOT_DISK"
    ROOT_DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $ROOT_DISK_GB -ge 100 ]; then
        log_pass "磁盘空间充足 (>= 100GB)"
    elif [ $ROOT_DISK_GB -ge 50 ]; then
        log_warn "磁盘空间为 ${ROOT_DISK}，建议100GB以上"
    else
        log_fail "磁盘空间不足，最低需要50GB，建议100GB以上"
    fi
}

# 检查网络连接
check_network() {
    log_section "网络连接检查"
    
    # 检查网络接口
    IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    if [ -n "$IP_ADDRESS" ]; then
        log_pass "检测到IP地址: $IP_ADDRESS"
    else
        log_fail "未检测到有效的IP地址"
    fi
    
    # 检查DNS解析
    if ping -c 1 -W 2 www.baidu.com &> /dev/null; then
        log_pass "外网连接正常 (www.baidu.com)"
    else
        log_warn "无法连接外网，部署时可能需要配置代理或使用离线安装"
    fi
    
    # 检查国内镜像源
    if curl -s --connect-timeout 3 https://mirrors.aliyun.com &> /dev/null; then
        log_pass "阿里云镜像源可访问"
    else
        log_warn "阿里云镜像源不可访问，可能影响安装速度"
    fi
}

# 检查必要的命令
check_commands() {
    log_section "必要命令检查"
    
    # 检查Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        log_pass "Python3 已安装: $PYTHON_VERSION"
    else
        log_fail "Python3 未安装，请先安装: dnf install -y python3"
    fi
    
    # 检查Ansible
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n 1 | awk '{print $2}')
        log_pass "Ansible 已安装: $ANSIBLE_VERSION"
    else
        log_fail "Ansible 未安装，请先安装: dnf install -y ansible"
    fi
    
    # 检查Git
    if command -v git &> /dev/null; then
        log_pass "Git 已安装"
    else
        log_warn "Git 未安装，建议安装: dnf install -y git"
    fi
    
    # 检查常用工具
    for cmd in curl wget vim; do
        if command -v $cmd &> /dev/null; then
            log_pass "$cmd 已安装"
        else
            log_warn "$cmd 未安装，建议安装: dnf install -y $cmd"
        fi
    done
}

# 检查防火墙
check_firewall() {
    log_section "防火墙检查"
    
    if systemctl is-active --quiet firewalld; then
        log_pass "firewalld 正在运行"
        
        # 检查关键端口
        REQUIRED_PORTS=("6443/tcp" "2379-2380/tcp" "10250/tcp" "10251/tcp" "10252/tcp")
        for port in "${REQUIRED_PORTS[@]}"; do
            if firewall-cmd --list-ports | grep -q "$port"; then
                log_pass "端口 $port 已开放"
            else
                log_warn "端口 $port 未开放，部署时会自动配置"
            fi
        done
    else
        log_warn "firewalld 未运行，将在部署时启动"
    fi
}

# 检查SELinux
check_selinux() {
    log_section "SELinux 检查"
    
    if command -v getenforce &> /dev/null; then
        SELINUX_STATUS=$(getenforce)
        log_info "SELinux 状态: $SELINUX_STATUS"
        
        if [ "$SELINUX_STATUS" == "Disabled" ]; then
            log_pass "SELinux 已禁用"
        else
            log_warn "SELinux 状态为 $SELINUX_STATUS，部署时会禁用并重启系统"
        fi
    else
        log_warn "无法检测 SELinux 状态"
    fi
}

# 检查Swap
check_swap() {
    log_section "Swap 检查"
    
    SWAP_SIZE=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$SWAP_SIZE" -eq 0 ]; then
        log_pass "Swap 已禁用"
    else
        log_warn "Swap 当前启用 (${SWAP_SIZE}MB)，部署时会禁用"
    fi
}

# 检查端口占用
check_ports() {
    log_section "端口占用检查"
    
    CRITICAL_PORTS=(6443 2379 2380 10250 10251 10252 9090 3000 8080 8081 5000)
    
    for port in "${CRITICAL_PORTS[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            log_warn "端口 $port 已被占用，可能导致服务无法启动"
        else
            log_pass "端口 $port 可用"
        fi
    done
}

# 检查Docker
check_docker() {
    log_section "Docker 检查"
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_info "Docker 已安装: $DOCKER_VERSION"
        
        if systemctl is-active --quiet docker; then
            log_pass "Docker 服务正在运行"
        else
            log_warn "Docker 已安装但未运行"
        fi
    else
        log_info "Docker 未安装，将在部署时安装"
    fi
}

# 检查Kubernetes
check_kubernetes() {
    log_section "Kubernetes 检查"
    
    if command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(kubectl version --client -o json 2>/dev/null | grep -oP '"gitVersion":"\K[^"]+' || echo "unknown")
        log_warn "kubectl 已安装: $KUBECTL_VERSION (如果已有集群，建议先清理)"
    else
        log_info "kubectl 未安装，将在部署时安装"
    fi
    
    if command -v kubeadm &> /dev/null; then
        log_warn "kubeadm 已安装，如果已有集群，建议先执行: kubeadm reset"
    else
        log_info "kubeadm 未安装，将在部署时安装"
    fi
}

# 检查项目文件
check_project_files() {
    log_section "项目文件检查"
    
    REQUIRED_FILES=(
        "ansible.cfg"
        "site.yml"
        "inventory/single-node.yml"
        "playbooks/01-common-setup.yml"
        "playbooks/02-docker-setup.yml"
        "playbooks/03-kubernetes-fixed.yml"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_pass "文件存在: $file"
        else
            log_fail "文件缺失: $file"
        fi
    done
}

# 检查SSH配置
check_ssh() {
    log_section "SSH 配置检查"
    
    if [ -f ~/.ssh/id_rsa ]; then
        log_pass "SSH密钥已存在"
    else
        log_warn "SSH密钥不存在，建议创建: ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
    fi
    
    if systemctl is-active --quiet sshd; then
        log_pass "SSH服务正在运行"
    else
        log_fail "SSH服务未运行"
    fi
}

# 生成部署建议
generate_recommendations() {
    log_section "部署建议"
    
    echo ""
    echo "基于检查结果，提供以下建议："
    echo ""
    
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "${RED}❌ 发现 $FAIL_COUNT 个严重问题，建议修复后再部署${NC}"
        echo ""
    fi
    
    if [ $WARN_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠️  发现 $WARN_COUNT 个警告，建议注意${NC}"
        echo ""
    fi
    
    if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ 所有检查通过，可以开始部署！${NC}"
        echo ""
        echo "建议的部署命令："
        echo "  ./deploy-single.sh              # 单节点完整部署"
        echo "  ./deploy-single.sh --check      # 先运行检查模式"
        echo ""
    fi
    
    # 快速修复建议
    if [ $FAIL_COUNT -gt 0 ] || [ $WARN_COUNT -gt 0 ]; then
        echo "快速修复命令："
        echo ""
        
        if ! command -v ansible &> /dev/null; then
            echo "# 安装Ansible"
            echo "dnf install -y epel-release"
            echo "dnf install -y ansible"
            echo ""
        fi
        
        if ! command -v python3 &> /dev/null; then
            echo "# 安装Python3"
            echo "dnf install -y python3 python3-pip"
            echo ""
        fi
        
        if [ ! -f ~/.ssh/id_rsa ]; then
            echo "# 生成SSH密钥"
            echo "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
            echo ""
        fi
        
        echo "# 安装基础工具"
        echo "dnf install -y curl wget vim git net-tools"
        echo ""
    fi
}

# 显示摘要
show_summary() {
    log_section "检查摘要"
    
    echo ""
    echo -e "通过: ${GREEN}$PASS_COUNT${NC} 项"
    echo -e "警告: ${YELLOW}$WARN_COUNT${NC} 项"
    echo -e "失败: ${RED}$FAIL_COUNT${NC} 项"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}系统基本满足部署要求！${NC}"
        return 0
    else
        echo -e "${RED}系统不满足部署要求，请先解决上述问题${NC}"
        return 1
    fi
}

# 主函数
main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     云原生 DevOps 平台 - 部署前环境检查                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log_info "开始环境检查..."
    echo ""
    
    check_system_info
    check_hardware
    check_network
    check_commands
    check_firewall
    check_selinux
    check_swap
    check_ports
    check_docker
    check_kubernetes
    check_ssh
    check_project_files
    
    generate_recommendations
    show_summary
    
    echo ""
    log_info "检查完成！"
    echo ""
}

# 运行主函数
main

