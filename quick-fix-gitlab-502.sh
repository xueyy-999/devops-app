#!/bin/bash
# GitLab 502 错误快速修复脚本
# 用于自动诊断和修复GitLab 502 Bad Gateway问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "GitLab 502 错误快速修复脚本"
echo "==========================================${NC}"
echo ""

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请以root用户运行此脚本${NC}"
    exit 1
fi

FIX_COUNT=0
CRITICAL_ERRORS=0

# 修复1: 检查并修复SELinux（最关键）
echo -e "${BLUE}[1/8] 检查SELinux状态${NC}"
SELINUX_STATUS=$(getenforce)
echo "SELinux当前状态: $SELINUX_STATUS"

if [ "$SELINUX_STATUS" = "Enforcing" ]; then
    echo -e "${YELLOW}SELinux处于Enforcing状态，这是导致502错误的最常见原因！${NC}"
    echo "正在临时禁用SELinux..."
    setenforce 0
    echo -e "${GREEN}✓ SELinux已临时设置为Permissive${NC}"
    
    echo "正在永久禁用SELinux..."
    sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
    echo -e "${GREEN}✓ SELinux已永久禁用（重启后生效）${NC}"
    
    FIX_COUNT=$((FIX_COUNT+1))
elif [ "$SELINUX_STATUS" = "Permissive" ]; then
    echo -e "${GREEN}✓ SELinux处于Permissive模式（OK）${NC}"
else
    echo -e "${GREEN}✓ SELinux已禁用${NC}"
fi
echo ""

# 修复2: 检查并修复PostgreSQL
echo -e "${BLUE}[2/8] 检查PostgreSQL${NC}"
if ! systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}PostgreSQL未运行，正在启动...${NC}"
    systemctl start postgresql
    systemctl enable postgresql
    sleep 5
    FIX_COUNT=$((FIX_COUNT+1))
fi

if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ PostgreSQL运行中${NC}"
    
    # 测试连接
    if sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
        echo -e "${GREEN}✓ PostgreSQL连接正常${NC}"
    else
        echo -e "${RED}✗ PostgreSQL无法连接${NC}"
        CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
    fi
    
    # 检查GitLab数据库
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw gitlabhq_production; then
        echo -e "${GREEN}✓ GitLab数据库存在${NC}"
    else
        echo -e "${RED}✗ GitLab数据库不存在${NC}"
        CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
    fi
else
    echo -e "${RED}✗ PostgreSQL未运行${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi
echo ""

# 修复3: 检查并修复Redis
echo -e "${BLUE}[3/8] 检查Redis${NC}"
if ! systemctl is-active --quiet redis; then
    echo -e "${YELLOW}Redis未运行，正在启动...${NC}"
    systemctl start redis
    systemctl enable redis
    sleep 3
    FIX_COUNT=$((FIX_COUNT+1))
fi

if systemctl is-active --quiet redis; then
    echo -e "${GREEN}✓ Redis运行中${NC}"
    
    # 测试连接
    if redis-cli ping &>/dev/null; then
        echo -e "${GREEN}✓ Redis连接正常${NC}"
    else
        echo -e "${RED}✗ Redis无法连接${NC}"
        CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
    fi
else
    echo -e "${RED}✗ Redis未运行${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi
echo ""

# 修复4: 检查pg_hba.conf配置
echo -e "${BLUE}[4/8] 检查PostgreSQL认证配置${NC}"
if [ -f "/var/lib/pgsql/data/pg_hba.conf" ]; then
    # 检查是否有trust配置
    if grep -q "trust" /var/lib/pgsql/data/pg_hba.conf; then
        echo -e "${YELLOW}发现trust认证，建议改为md5${NC}"
        echo "但为了确保GitLab能连接，暂时保持trust"
    fi
    
    # 检查GitLab用户连接（使用trust）
    if sudo -u postgres psql -h 127.0.0.1 -U gitlab -d gitlabhq_production -c "SELECT 1" &>/dev/null; then
        echo -e "${GREEN}✓ GitLab数据库用户可以连接${NC}"
    else
        echo -e "${YELLOW}GitLab数据库用户连接失败，尝试修复...${NC}"
        
        # 临时改回trust
        sed -i 's/\bmd5\b/trust/g' /var/lib/pgsql/data/pg_hba.conf
        systemctl restart postgresql
        sleep 5
        
        if sudo -u postgres psql -h 127.0.0.1 -U gitlab -d gitlabhq_production -c "SELECT 1" &>/dev/null; then
            echo -e "${GREEN}✓ 修复成功：数据库认证已改为trust${NC}"
            FIX_COUNT=$((FIX_COUNT+1))
        else
            echo -e "${RED}✗ 修复失败：数据库连接仍然失败${NC}"
            CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
        fi
    fi
else
    echo -e "${YELLOW}⚠ pg_hba.conf文件不存在${NC}"
fi
echo ""

# 修复5: 重启GitLab服务
echo -e "${BLUE}[5/8] 检查GitLab服务${NC}"
if ! systemctl is-active --quiet gitlab-runsvdir.service; then
    echo -e "${YELLOW}GitLab服务未运行，正在启动...${NC}"
    gitlab-ctl start
    sleep 10
    FIX_COUNT=$((FIX_COUNT+1))
fi

echo "重启GitLab以应用所有修复..."
gitlab-ctl restart
sleep 15

echo "GitLab组件状态:"
gitlab-ctl status | while read line; do
    if echo "$line" | grep -q "^run:"; then
        echo -e "  ${GREEN}✓${NC} $line"
    elif echo "$line" | grep -q "^down:"; then
        echo -e "  ${RED}✗${NC} $line"
        service=$(echo "$line" | awk '{print $2}' | cut -d: -f1)
        echo "    尝试重启 $service..."
        gitlab-ctl restart "$service" &>/dev/null || true
    else
        echo "  $line"
    fi
done
echo ""

# 修复6: 检查Nginx
echo -e "${BLUE}[6/8] 检查外部Nginx${NC}"
if ! systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}Nginx未运行，正在启动...${NC}"
    if nginx -t &>/dev/null; then
        systemctl start nginx
        systemctl enable nginx
        echo -e "${GREEN}✓ Nginx已启动${NC}"
        FIX_COUNT=$((FIX_COUNT+1))
    else
        echo -e "${RED}✗ Nginx配置有错误${NC}"
        nginx -t
        CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
    fi
else
    echo -e "${GREEN}✓ Nginx运行中${NC}"
    # 重启Nginx以应用修复
    systemctl restart nginx
fi
echo ""

# 修复7: 等待GitLab完全启动
echo -e "${BLUE}[7/8] 等待GitLab完全启动${NC}"
echo "这可能需要5-10分钟，请耐心等待..."

MAX_WAIT=600  # 10分钟
WAIT_TIME=0
SLEEP_INTERVAL=10
READY=false

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # 检查GitLab readiness
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8081/-/readiness 2>/dev/null || echo "000")
    
    # 检查组件状态
    RUNNING_SERVICES=$(gitlab-ctl status 2>/dev/null | grep -c "^run:" || echo "0")
    TOTAL_SERVICES=$(gitlab-ctl status 2>/dev/null | wc -l || echo "1")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ GitLab已完全就绪！（${WAIT_TIME}秒）${NC}"
        READY=true
        break
    else
        echo -e "${YELLOW}等待中... (${WAIT_TIME}s/${MAX_WAIT}s, 就绪状态: ${HTTP_CODE}, 服务: ${RUNNING_SERVICES}/${TOTAL_SERVICES})${NC}"
        sleep $SLEEP_INTERVAL
        WAIT_TIME=$((WAIT_TIME + SLEEP_INTERVAL))
    fi
done

if [ "$READY" = false ]; then
    echo -e "${RED}✗ GitLab未在预期时间内就绪${NC}"
    echo "当前组件状态:"
    gitlab-ctl status
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi
echo ""

# 修复8: 测试所有端点
echo -e "${BLUE}[8/8] 测试GitLab连接${NC}"
IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo "测试1: 内部就绪探针 (http://127.0.0.1:8081/-/readiness)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8081/-/readiness 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} 状态码: $HTTP_CODE (OK)"
else
    echo -e "  ${RED}✗${NC} 状态码: $HTTP_CODE (失败)"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi

echo "测试2: 内部根路径 (http://127.0.0.1:8081/)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8081/ 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" =~ ^(200|302)$ ]]; then
    echo -e "  ${GREEN}✓${NC} 状态码: $HTTP_CODE (OK)"
else
    echo -e "  ${RED}✗${NC} 状态码: $HTTP_CODE (失败)"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi

echo "测试3: 外部根路径 (http://${IP}/)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP}/ 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" =~ ^(200|302)$ ]]; then
    echo -e "  ${GREEN}✓${NC} 状态码: $HTTP_CODE (OK)"
else
    echo -e "  ${RED}✗${NC} 状态码: $HTTP_CODE (失败)"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi

echo "测试4: API版本接口 (http://${IP}/api/v4/version)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP}/api/v4/version 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" =~ ^(200|401)$ ]]; then
    echo -e "  ${GREEN}✓${NC} 状态码: $HTTP_CODE (OK，401是正常的未授权响应)"
else
    echo -e "  ${RED}✗${NC} 状态码: $HTTP_CODE (失败)"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS+1))
fi
echo ""

# 总结
echo -e "${BLUE}=========================================="
echo "修复完成"
echo "==========================================${NC}"
echo -e "${GREEN}执行了 ${FIX_COUNT} 项修复${NC}"

if [ $CRITICAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有关键检查通过！${NC}"
    echo ""
    echo -e "${BLUE}GitLab访问信息:${NC}"
    echo "  外部访问: http://${IP}/"
    echo "  API接口: http://${IP}/api/v4/"
    echo "  默认用户: root"
    echo "  初始密码: 查看 /etc/gitlab/initial_root_password"
    echo ""
    echo "如果仍有问题，运行详细诊断:"
    echo "  ./scripts/gitlab-diagnosis.sh"
    exit 0
else
    echo -e "${RED}✗ 发现 ${CRITICAL_ERRORS} 个关键错误${NC}"
    echo ""
    echo -e "${YELLOW}建议操作:${NC}"
    echo "1. 查看GitLab详细日志:"
    echo "   gitlab-ctl tail puma"
    echo "   gitlab-ctl tail nginx"
    echo "   tail -100 /var/log/gitlab/gitlab-rails/production.log"
    echo ""
    echo "2. 运行完整诊断:"
    echo "   ./scripts/gitlab-diagnosis.sh"
    echo ""
    echo "3. 查看排查文档:"
    echo "   cat GITLAB_TROUBLESHOOTING.md"
    echo ""
    echo "4. 检查系统资源:"
    echo "   free -h"
    echo "   df -h"
    exit 1
fi
