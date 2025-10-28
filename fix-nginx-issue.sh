#!/bin/bash

# Nginx 问题修复脚本
# 用于虚拟机环境

set -e

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "=========================================="
log_info "  Nginx 问题诊断和修复"
log_info "=========================================="

# 1. 检查 nginx 是否安装
log_info "检查 nginx 安装状态..."
if ! command -v nginx &> /dev/null; then
    log_error "nginx 未安装，正在安装..."
    dnf install -y nginx
    log_success "nginx 安装完成"
else
    log_success "nginx 已安装: $(nginx -v 2>&1)"
fi

# 2. 检查 nginx 用户
log_info "检查 nginx 用户..."
if ! id nginx &> /dev/null; then
    log_warning "nginx 用户不存在，正在创建..."
    useradd -r -M -s /sbin/nologin nginx
    log_success "nginx 用户创建完成"
else
    log_success "nginx 用户已存在"
fi

# 3. 创建必要的目录
log_info "创建 nginx 目录..."
mkdir -p /var/log/nginx
mkdir -p /etc/nginx/conf.d
mkdir -p /usr/share/nginx/html
chown -R nginx:nginx /var/log/nginx
log_success "目录创建完成"

# 4. 检查端口占用
log_info "检查端口占用情况..."
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    log_warning "80 端口被占用！"
    log_info "占用 80 端口的进程:"
    netstat -tulnp | grep ":80 " || ss -tulnp | grep ":80 "
    
    read -p "是否停止占用 80 端口的服务? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 尝试停止常见的占用 80 端口的服务
        for service in httpd apache2 gitlab; do
            if systemctl is-active --quiet $service; then
                log_info "停止 $service..."
                systemctl stop $service
            fi
        done
    fi
else
    log_success "80 端口未被占用"
fi

# 5. 检查 SELinux 状态
log_info "检查 SELinux 状态..."
if command -v getenforce &> /dev/null; then
    selinux_status=$(getenforce)
    if [ "$selinux_status" != "Disabled" ]; then
        log_warning "SELinux 状态: $selinux_status"
        log_info "设置 SELinux 允许 nginx 网络连接..."
        setsebool -P httpd_can_network_connect 1 2>/dev/null || true
    fi
fi

# 6. 测试 nginx 配置
log_info "测试 nginx 配置..."
if nginx -t; then
    log_success "nginx 配置语法正确"
else
    log_error "nginx 配置有错误！"
    log_info "配置文件: /etc/nginx/nginx.conf"
    exit 1
fi

# 7. 尝试启动 nginx
log_info "尝试启动 nginx..."
if systemctl start nginx; then
    log_success "nginx 启动成功！"
    systemctl enable nginx
    log_success "nginx 已设置为开机自启"
else
    log_error "nginx 启动失败！"
    log_info "查看详细错误:"
    journalctl -xeu nginx.service -n 50
    exit 1
fi

# 8. 检查 nginx 状态
log_info "检查 nginx 运行状态..."
if systemctl is-active --quiet nginx; then
    log_success "nginx 运行正常"
    log_info "nginx 进程:"
    ps aux | grep nginx | grep -v grep
else
    log_error "nginx 未运行"
    exit 1
fi

# 9. 测试 nginx 响应
log_info "测试 nginx 响应..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
    log_success "nginx 响应正常"
else
    log_warning "nginx 响应异常，可能需要配置"
fi

log_info ""
log_success "=========================================="
log_success "  修复完成！"
log_success "=========================================="
log_info ""
log_info "nginx 状态: $(systemctl is-active nginx)"
log_info "监听端口:"
netstat -tuln | grep nginx || ss -tuln | grep nginx
log_info ""
log_info "有用的命令:"
log_info "  查看状态: systemctl status nginx"
log_info "  查看日志: journalctl -u nginx -f"
log_info "  测试配置: nginx -t"
log_info "  重启服务: systemctl restart nginx"
log_info ""

