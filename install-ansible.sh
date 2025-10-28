#!/bin/bash

# Ansible 快速安装脚本
# 适用于 CentOS/Rocky Linux 9

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "开始安装 Ansible..."

# 检查是否已安装
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    log_info "Ansible 已安装: $ANSIBLE_VERSION"
    read -p "是否重新安装? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "跳过安装"
        exit 0
    fi
fi

# 安装 EPEL 仓库
log_info "安装 EPEL 仓库..."
if ! dnf repolist | grep -q epel; then
    dnf install -y epel-release || {
        log_error "EPEL 仓库安装失败"
        exit 1
    }
    log_success "EPEL 仓库安装成功"
else
    log_info "EPEL 仓库已存在"
fi

# 启用 CRB 仓库（CentOS Stream 9）
log_info "启用 CRB 仓库..."
dnf config-manager --set-enabled crb || {
    log_info "CRB 仓库可能不存在（Rocky Linux 使用 PowerTools）"
    dnf config-manager --set-enabled powertools || true
}

# 更新缓存
log_info "更新 DNF 缓存..."
dnf makecache

# 安装 Python3 和依赖
log_info "安装 Python3 及依赖..."
dnf install -y python3 python3-pip python3-devel || {
    log_error "Python3 安装失败"
    exit 1
}

# 安装 Ansible
log_info "安装 Ansible..."
dnf install -y ansible || {
    log_error "Ansible 从 DNF 安装失败，尝试使用 pip 安装..."
    pip3 install ansible || {
        log_error "Ansible 安装失败"
        exit 1
    }
}

# 安装 Ansible 相关工具
log_info "安装 Ansible 相关依赖..."
dnf install -y sshpass || log_info "sshpass 安装失败（可选）"

# 安装 Ansible 社区模块
log_info "安装 Ansible 社区模块..."
pip3 install --upgrade pip
ansible-galaxy collection install community.general || log_info "community.general 安装失败（可选）"
ansible-galaxy collection install community.docker || log_info "community.docker 安装失败（可选）"
ansible-galaxy collection install community.postgresql || log_info "community.postgresql 安装失败（可选）"
ansible-galaxy collection install kubernetes.core || log_info "kubernetes.core 安装失败（可选）"

# 安装 Python 库
log_info "安装 Python 依赖库..."
pip3 install jinja2 pyyaml paramiko netaddr || log_info "部分 Python 库安装失败（可选）"

# 验证安装
log_info "验证 Ansible 安装..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    log_success "Ansible 安装成功: $ANSIBLE_VERSION"
    
    echo ""
    echo "安装信息："
    ansible --version
    
    echo ""
    log_success "所有依赖安装完成！"
    echo ""
    echo "下一步操作："
    echo "  1. 运行预检查: ./pre-check.sh"
    echo "  2. 配置inventory: vim inventory/single-node.yml"
    echo "  3. 开始部署: ./deploy-single.sh"
    echo ""
else
    log_error "Ansible 安装失败，请检查错误信息"
    exit 1
fi

