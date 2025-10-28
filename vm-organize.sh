#!/bin/bash

# 虚拟机项目整理脚本
# 在虚拟机上运行此脚本以整理项目结构

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "======================================"
log_info "云原生 DevOps 平台项目整理脚本"
log_info "======================================"

# 获取项目根目录
PROJECT_ROOT=$(pwd)
log_info "项目根目录: $PROJECT_ROOT"

# 1. 创建 docs 目录
log_info "创建 docs 目录..."
mkdir -p docs
log_success "docs 目录创建完成"

# 2. 创建 .gitignore
log_info "创建 .gitignore 文件..."
cat > .gitignore << 'EOF'
# Ansible
*.retry
.vault_pass
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
ENV/
env/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Temporary files
tmp/
temp/
*.tmp
*.bak
*.backup

# Kubernetes
*.kubeconfig
kubeconfig
admin.conf

# Secrets
*.key
*.pem
*.crt
secrets/
.env
.env.local

# Backup files
backup/
*.tar.gz
*.zip

# OS
Thumbs.db
.DS_Store

# Documentation
docs/_build/
site/

# Test
.pytest_cache/
.coverage
htmlcov/
.tox/

# Custom
inventory/hosts.yml
inventory/single-node.yml
!inventory/hosts.yml.example
!inventory/single-node.yml.example
EOF
log_success ".gitignore 文件创建完成"

# 3. 创建 LICENSE
log_info "创建 LICENSE 文件..."
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Cloud Native DevOps Platform Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
log_success "LICENSE 文件创建完成"

# 4. 创建 inventory 示例文件
log_info "创建 inventory 示例文件..."

# 备份现有的 inventory 文件（如果存在）
if [ -f "inventory/hosts.yml" ]; then
    log_warning "检测到现有 inventory/hosts.yml，创建备份..."
    cp inventory/hosts.yml inventory/hosts.yml.backup
fi

if [ -f "inventory/single-node.yml" ]; then
    log_warning "检测到现有 inventory/single-node.yml，创建备份..."
    cp inventory/single-node.yml inventory/single-node.yml.backup
fi

# 创建示例文件（文件内容会在后续步骤中下载或创建）
log_success "inventory 备份完成"

# 5. 创建部署脚本（如果不存在）
log_info "检查部署脚本..."

if [ ! -f "deploy.sh" ]; then
    log_info "创建 deploy.sh..."
    # 这里需要创建部署脚本
    log_warning "deploy.sh 不存在，需要手动创建或从源复制"
fi

if [ ! -f "deploy-single.sh" ]; then
    log_info "创建 deploy-single.sh..."
    log_warning "deploy-single.sh 不存在，需要手动创建或从源复制"
fi

# 6. 创建 scripts 目录下的文件
log_info "检查 scripts 目录..."
mkdir -p scripts

if [ ! -f "scripts/backup.sh" ]; then
    log_warning "scripts/backup.sh 不存在，建议创建"
fi

if [ ! -f "scripts/health-check.sh" ]; then
    log_warning "scripts/health-check.sh 不存在，建议创建"
fi

if [ ! -f "scripts/quick-verify.sh" ]; then
    log_warning "scripts/quick-verify.sh 不存在，建议创建"
fi

# 7. 清理不必要的文件
log_info "检查是否有不必要的文件..."

# 删除空的 group_vars 和 host_vars（如果为空）
if [ -d "group_vars" ] && [ -z "$(ls -A group_vars)" ]; then
    log_warning "删除空的 group_vars 目录"
    rmdir group_vars
fi

if [ -d "host_vars" ] && [ -z "$(ls -A host_vars)" ]; then
    log_warning "删除空的 host_vars 目录"
    rmdir host_vars
fi

# 删除错误的文件
if [ -f "inventory/06-application-deploy" ]; then
    log_warning "删除错误的文件: inventory/06-application-deploy"
    rm -f inventory/06-application-deploy
fi

# 8. 设置文件权限
log_info "设置文件权限..."
chmod +x *.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
log_success "文件权限设置完成"

# 9. 显示整理后的结构
log_info ""
log_info "======================================"
log_success "项目整理完成！"
log_info "======================================"
log_info ""
log_info "整理后的项目结构:"
tree -L 2 -I '__pycache__|*.pyc|.git' 2>/dev/null || ls -lR

log_info ""
log_info "======================================"
log_info "下一步操作："
log_info "======================================"
log_info "1. 查看备份文件（如有）："
log_info "   - inventory/hosts.yml.backup"
log_info "   - inventory/single-node.yml.backup"
log_info ""
log_info "2. 从 Windows 环境同步文档文件："
log_info "   scp -r user@windows-host:d:/3/docs/* $PROJECT_ROOT/docs/"
log_info ""
log_info "3. 从 Windows 环境同步其他文件："
log_info "   scp user@windows-host:d:/3/README.md $PROJECT_ROOT/"
log_info "   scp user@windows-host:d:/3/CHANGELOG.md $PROJECT_ROOT/"
log_info "   scp user@windows-host:d:/3/inventory/*.example $PROJECT_ROOT/inventory/"
log_info ""
log_info "4. 或者使用提供的文档创建脚本："
log_info "   bash create-docs.sh"
log_info ""
log_info "======================================"

log_success "整理脚本执行完成！"

