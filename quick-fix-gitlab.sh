#!/bin/bash
# GitLab 快速修复脚本
# 用于自动检测并修复常见的GitLab问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "GitLab 快速修复脚本"
echo "==========================================${NC}"
echo ""

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请以root用户运行此脚本${NC}"
    exit 1
fi

# 记录开始时间
START_TIME=$(date +%s)

# 修复计数
FIX_COUNT=0

# 1. 检查并启动PostgreSQL
echo -e "${BLUE}[1/8] 检查PostgreSQL...${NC}"
if ! systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}PostgreSQL未运行，正在启动...${NC}"
    systemctl start postgresql
    systemctl enable postgresql
    sleep 3
    if systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✓ PostgreSQL已启动${NC}"
        FIX_COUNT=$((FIX_COUNT+1))
    else
        echo -e "${RED}✗ PostgreSQL启动失败${NC}"
    fi
else
    echo -e "${GREEN}✓ PostgreSQL运行正常${NC}"
fi

# 2. 检查并启动Redis
echo -e "${BLUE}[2/8] 检查Redis...${NC}"
if ! systemctl is-active --quiet redis; then
    echo -e "${YELLOW}Redis未运行，正在启动...${NC}"
    systemctl start redis
    systemctl enable redis
    sleep 2
    if systemctl is-active --quiet redis; then
        echo -e "${GREEN}✓ Redis已启动${NC}"
        FIX_COUNT=$((FIX_COUNT+1))
    else
        echo -e "${RED}✗ Redis启动失败${NC}"
    fi
else
    echo -e "${GREEN}✓ Redis运行正常${NC}"
fi

# 3. 检查磁盘空间
echo -e "${BLUE}[3/8] 检查磁盘空间...${NC}"
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${YELLOW}磁盘使用率${DISK_USAGE}%，正在清理...${NC}"
    
    # 清理旧日志（7天前）
    find /var/log/gitlab -name "*.log" -mtime +7 -exec rm -f {} \; 2>/dev/null || true
    
    # 清理旧备份（7天前）
    find /var/opt/gitlab/backups -name "*.tar" -mtime +7 -exec rm -f {} \; 2>/dev/null || true
    
    # 清理Docker
    docker system prune -f 2>/dev/null || true
    
    DISK_USAGE_AFTER=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo -e "${GREEN}✓ 磁盘清理完成（${DISK_USAGE}% → ${DISK_USAGE_AFTER}%）${NC}"
    FIX_COUNT=$((FIX_COUNT+1))
else
    echo -e "${GREEN}✓ 磁盘空间充足（${DISK_USAGE}%）${NC}"
fi

# 4. 检查内存
echo -e "${BLUE}[4/8] 检查内存...${NC}"
FREE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
if [ "$FREE_MEM" -lt 512 ]; then
    echo -e "${YELLOW}可用内存不足（${FREE_MEM}MB），正在清理缓存...${NC}"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    FREE_MEM_AFTER=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    echo -e "${GREEN}✓ 内存清理完成（${FREE_MEM}MB → ${FREE_MEM_AFTER}MB）${NC}"
    FIX_COUNT=$((FIX_COUNT+1))
else
    echo -e "${GREEN}✓ 内存充足（${FREE_MEM}MB可用）${NC}"
fi

# 5. 检查GitLab配置
echo -e "${BLUE}[5/8] 检查GitLab配置...${NC}"
if [ ! -f "/etc/gitlab/gitlab.rb" ]; then
    echo -e "${RED}✗ /etc/gitlab/gitlab.rb 不存在${NC}"
else
    # 检查关键配置
    EXTERNAL_URL=$(grep "^external_url" /etc/gitlab/gitlab.rb | head -1)
    NGINX_PORT=$(grep "^nginx\['listen_port'\]" /etc/gitlab/gitlab.rb | head -1)
    
    if [ -z "$EXTERNAL_URL" ]; then
        echo -e "${YELLOW}⚠ external_url 未设置${NC}"
    else
        echo -e "${GREEN}✓ 配置: $EXTERNAL_URL${NC}"
    fi
    
    if [ -n "$NGINX_PORT" ]; then
        echo -e "${GREEN}✓ 配置: $NGINX_PORT${NC}"
    fi
fi

# 6. 检查并修复GitLab服务
echo -e "${BLUE}[6/8] 检查GitLab服务...${NC}"
if ! systemctl is-active --quiet gitlab-runsvdir.service; then
    echo -e "${YELLOW}GitLab服务未运行，正在启动...${NC}"
    gitlab-ctl start
    sleep 10
    FIX_COUNT=$((FIX_COUNT+1))
fi

# 检查各个组件
echo "检查GitLab组件状态:"
gitlab-ctl status | while read line; do
    if echo "$line" | grep -q "down:"; then
        SERVICE=$(echo "$line" | awk '{print $2}' | cut -d: -f1)
        echo -e "${YELLOW}正在重启 $SERVICE...${NC}"
        gitlab-ctl restart "$SERVICE" 2>/dev/null || true
        FIX_COUNT=$((FIX_COUNT+1))
    fi
done

# 7. 检查并修复Nginx
echo -e "${BLUE}[7/8] 检查Nginx...${NC}"
if ! systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}Nginx未运行，正在启动...${NC}"
    
    # 测试配置
    if nginx -t 2>/dev/null; then
        systemctl start nginx
        systemctl enable nginx
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}✓ Nginx已启动${NC}"
            FIX_COUNT=$((FIX_COUNT+1))
        fi
    else
        echo -e "${RED}✗ Nginx配置有错误${NC}"
        nginx -t 2>&1
    fi
else
    echo -e "${GREEN}✓ Nginx运行正常${NC}"
fi

# 8. 等待GitLab就绪
echo -e "${BLUE}[8/8] 等待GitLab就绪...${NC}"
echo "这可能需要几分钟，请耐心等待..."

MAX_WAIT=300  # 最多等待5分钟
WAIT_TIME=0
SLEEP_INTERVAL=10

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8081/-/readiness 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ GitLab已就绪（${WAIT_TIME}秒）${NC}"
        break
    else
        echo -e "${YELLOW}等待中... (${WAIT_TIME}s/${MAX_WAIT}s, 状态码: ${HTTP_CODE})${NC}"
        sleep $SLEEP_INTERVAL
        WAIT_TIME=$((WAIT_TIME + SLEEP_INTERVAL))
    fi
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo -e "${RED}✗ GitLab未在预期时间内就绪${NC}"
    echo "请运行诊断脚本获取更多信息:"
    echo "  ./scripts/gitlab-diagnosis.sh"
fi

# 测试连接
echo ""
echo -e "${BLUE}=========================================="
echo "连接测试"
echo "==========================================${NC}"

IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo "测试内部连接 (127.0.0.1:8081):"
curl -I -s -o /dev/null -w "  状态码: %{http_code}\n" http://127.0.0.1:8081/ 2>/dev/null || echo -e "  ${RED}连接失败${NC}"

echo "测试外部连接 ($IP:80):"
curl -I -s -o /dev/null -w "  状态码: %{http_code}\n" http://${IP}/ 2>/dev/null || echo -e "  ${RED}连接失败${NC}"

echo "测试API端点 ($IP/api/v4/version):"
curl -s -o /dev/null -w "  状态码: %{http_code}\n" http://${IP}/api/v4/version 2>/dev/null || echo -e "  ${RED}连接失败${NC}"

# 计算总耗时
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}=========================================="
echo "修复完成"
echo "==========================================${NC}"
echo -e "${GREEN}执行了 ${FIX_COUNT} 项修复${NC}"
echo -e "${GREEN}总耗时: ${ELAPSED} 秒${NC}"
echo ""

if [ $FIX_COUNT -gt 0 ]; then
    echo -e "${YELLOW}建议：${NC}"
    echo "1. 等待2-3分钟后再运行验证脚本"
    echo "2. 如果问题仍然存在，运行详细诊断："
    echo "   ./scripts/gitlab-diagnosis.sh"
    echo "3. 查看排查文档："
    echo "   cat GITLAB_TROUBLESHOOTING.md"
else
    echo -e "${GREEN}所有服务运行正常！${NC}"
    echo "可以运行验证脚本了："
    echo "  ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml"
fi

echo ""
echo -e "${BLUE}快速命令：${NC}"
echo "  查看GitLab状态: gitlab-ctl status"
echo "  查看实时日志:   gitlab-ctl tail"
echo "  重启GitLab:     gitlab-ctl restart"
echo "  详细诊断:       ./scripts/gitlab-diagnosis.sh"


