#!/bin/bash
# GitLab 完整诊断脚本
# 用于排查 GitLab 500 错误和可达性问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "GitLab 完整诊断工具"
echo "=========================================="
echo ""

# 1. 检查系统资源
echo -e "${GREEN}[1/10] 检查系统资源${NC}"
echo "内存使用情况:"
free -h
echo ""
echo "磁盘使用情况:"
df -h | grep -E '(Filesystem|/dev/mapper|/dev/sd|/dev/vd)'
echo ""

# 2. 检查GitLab服务状态
echo -e "${GREEN}[2/10] 检查GitLab服务状态${NC}"
if systemctl is-active --quiet gitlab-runsvdir.service; then
    echo -e "${GREEN}✓ GitLab主服务运行中${NC}"
    gitlab-ctl status
else
    echo -e "${RED}✗ GitLab主服务未运行${NC}"
    systemctl status gitlab-runsvdir.service --no-pager || true
fi
echo ""

# 3. 检查PostgreSQL
echo -e "${GREEN}[3/10] 检查PostgreSQL数据库${NC}"
if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ PostgreSQL运行中${NC}"
    sudo -u postgres psql -c "SELECT version();" 2>/dev/null || echo -e "${RED}✗ 无法连接到PostgreSQL${NC}"
    sudo -u postgres psql -c "\l" 2>/dev/null | grep gitlabhq_production || echo -e "${YELLOW}⚠ gitlabhq_production 数据库不存在${NC}"
    echo ""
    echo "检查GitLab数据库连接:"
    sudo -u postgres psql gitlabhq_production -c "SELECT COUNT(*) FROM users;" 2>/dev/null || echo -e "${RED}✗ 无法查询GitLab数据库${NC}"
else
    echo -e "${RED}✗ PostgreSQL未运行${NC}"
fi
echo ""

# 4. 检查Redis
echo -e "${GREEN}[4/10] 检查Redis服务${NC}"
if systemctl is-active --quiet redis; then
    echo -e "${GREEN}✓ Redis运行中${NC}"
    redis-cli ping 2>/dev/null || echo -e "${RED}✗ 无法连接到Redis${NC}"
else
    echo -e "${RED}✗ Redis未运行${NC}"
fi
echo ""

# 5. 检查GitLab内置Nginx
echo -e "${GREEN}[5/10] 检查GitLab内置Nginx (8081)${NC}"
if netstat -tuln 2>/dev/null | grep -q ':8081' || ss -tuln 2>/dev/null | grep -q ':8081'; then
    echo -e "${GREEN}✓ GitLab内置Nginx监听在8081${NC}"
    netstat -tuln 2>/dev/null | grep ':8081' || ss -tuln 2>/dev/null | grep ':8081'
else
    echo -e "${RED}✗ GitLab内置Nginx未监听8081端口${NC}"
fi
echo ""

# 6. 检查外部Nginx
echo -e "${GREEN}[6/10] 检查外部Nginx (80)${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx运行中${NC}"
    nginx -t 2>&1 || echo -e "${RED}✗ Nginx配置有错误${NC}"
    netstat -tuln 2>/dev/null | grep ':80 ' || ss -tuln 2>/dev/null | grep ':80 '
else
    echo -e "${RED}✗ Nginx未运行${NC}"
    systemctl status nginx --no-pager || true
fi
echo ""

# 7. 检查端口占用
echo -e "${GREEN}[7/10] 检查关键端口占用${NC}"
echo "端口 80:"
netstat -tulnp 2>/dev/null | grep ':80 ' || ss -tulnp 2>/dev/null | grep ':80 ' || echo "未监听"
echo "端口 8081:"
netstat -tulnp 2>/dev/null | grep ':8081' || ss -tulnp 2>/dev/null | grep ':8081' || echo "未监听"
echo "端口 5432 (PostgreSQL):"
netstat -tulnp 2>/dev/null | grep ':5432' || ss -tulnp 2>/dev/null | grep ':5432' || echo "未监听"
echo "端口 6379 (Redis):"
netstat -tulnp 2>/dev/null | grep ':6379' || ss -tulnp 2>/dev/null | grep ':6379' || echo "未监听"
echo ""

# 8. 测试GitLab连接
echo -e "${GREEN}[8/10] 测试GitLab连接${NC}"
echo "测试内部连接 (127.0.0.1:8081):"
curl -I -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://127.0.0.1:8081/ 2>/dev/null || echo -e "${RED}✗ 连接失败${NC}"

echo "测试外部连接 (通过Nginx):"
IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
curl -I -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://${IP}/ 2>/dev/null || echo -e "${RED}✗ 连接失败${NC}"

echo "测试API端点:"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://${IP}/api/v4/version 2>/dev/null || echo -e "${RED}✗ API连接失败${NC}"

echo "测试就绪探针:"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://127.0.0.1:8081/-/readiness 2>/dev/null || echo -e "${RED}✗ 就绪探针失败${NC}"
echo ""

# 9. 检查GitLab日志（最近的错误）
echo -e "${GREEN}[9/10] 检查GitLab日志（最近20行错误）${NC}"
if [ -d "/var/log/gitlab" ]; then
    echo "=== Unicorn/Puma 日志 ==="
    if [ -f "/var/log/gitlab/unicorn/unicorn_stdout.log" ]; then
        tail -20 /var/log/gitlab/unicorn/unicorn_stdout.log | grep -i error || echo "无错误"
    elif [ -f "/var/log/gitlab/puma/puma_stdout.log" ]; then
        tail -20 /var/log/gitlab/puma/puma_stdout.log | grep -i error || echo "无错误"
    fi
    
    echo ""
    echo "=== GitLab应用日志 ==="
    if [ -f "/var/log/gitlab/gitlab-rails/production.log" ]; then
        tail -20 /var/log/gitlab/gitlab-rails/production.log | grep -E "(ERROR|FATAL)" || echo "无错误"
    fi
    
    echo ""
    echo "=== Nginx错误日志 ==="
    if [ -f "/var/log/gitlab/nginx/error.log" ]; then
        tail -20 /var/log/gitlab/nginx/error.log || echo "无错误"
    fi
else
    echo -e "${YELLOW}⚠ GitLab日志目录不存在${NC}"
fi
echo ""

# 10. 检查配置文件
echo -e "${GREEN}[10/10] 检查GitLab配置${NC}"
if [ -f "/etc/gitlab/gitlab.rb" ]; then
    echo "External URL:"
    grep "^external_url" /etc/gitlab/gitlab.rb || echo "未设置"
    
    echo "Nginx监听端口:"
    grep "^nginx\['listen_port'\]" /etc/gitlab/gitlab.rb || echo "使用默认"
    
    echo "数据库配置:"
    grep "^gitlab_rails\['db_" /etc/gitlab/gitlab.rb | grep -v password || echo "使用默认"
    
    echo "Redis配置:"
    grep "^redis\['enable'\]" /etc/gitlab/gitlab.rb || echo "使用默认"
    grep "^gitlab_rails\['redis_" /etc/gitlab/gitlab.rb || echo "使用默认"
else
    echo -e "${RED}✗ /etc/gitlab/gitlab.rb 不存在${NC}"
fi
echo ""

# 总结建议
echo "=========================================="
echo -e "${GREEN}诊断建议:${NC}"
echo "=========================================="

# 检查是否有明显问题
ISSUES=0

if ! systemctl is-active --quiet postgresql; then
    echo -e "${RED}1. PostgreSQL未运行，请启动: systemctl start postgresql${NC}"
    ISSUES=$((ISSUES+1))
fi

if ! systemctl is-active --quiet redis; then
    echo -e "${RED}2. Redis未运行，请启动: systemctl start redis${NC}"
    ISSUES=$((ISSUES+1))
fi

if ! systemctl is-active --quiet gitlab-runsvdir.service; then
    echo -e "${RED}3. GitLab服务未运行，请启动: gitlab-ctl start${NC}"
    ISSUES=$((ISSUES+1))
fi

if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}4. Nginx未运行，请启动: systemctl start nginx${NC}"
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ 所有基础服务都在运行${NC}"
    echo ""
    echo "如果仍然有500错误，请检查:"
    echo "1. 查看完整日志: journalctl -u gitlab-runsvdir -n 100"
    echo "2. 查看GitLab状态: gitlab-rake gitlab:check"
    echo "3. 重新配置GitLab: gitlab-ctl reconfigure"
    echo "4. 重启所有服务: gitlab-ctl restart"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="


