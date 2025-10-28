#!/bin/bash

# 修复Kubernetes仓库问题的脚本
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

log_info "修复Kubernetes仓库问题..."

# 1. 删除有问题的仓库文件
log_info "删除有问题的仓库文件..."
rm -f /etc/yum.repos.d/kubernetes.repo

# 2. 创建新的仓库配置
log_info "创建新的仓库配置..."
cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 3. 清理缓存
log_info "清理缓存..."
dnf clean all
dnf makecache

# 4. 测试仓库
log_info "测试仓库..."
dnf repolist | grep kubernetes

log_success "仓库修复完成！现在可以重新运行Kubernetes安装了。"
log_info "运行命令: ansible-playbook -i inventory/hosts.yml playbooks/03-kubernetes-fixed.yml"
