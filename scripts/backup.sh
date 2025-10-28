#!/bin/bash

# 云原生DevOps平台备份脚本
# 用于备份系统配置、应用数据和监控数据

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

# 配置变量
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="devops-platform-backup-${DATE}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "${BACKUP_PATH}"
    mkdir -p "${BACKUP_PATH}/kubernetes"
    mkdir -p "${BACKUP_PATH}/monitoring"
    mkdir -p "${BACKUP_PATH}/cicd"
    mkdir -p "${BACKUP_PATH}/applications"
    mkdir -p "${BACKUP_PATH}/system"
}

# 备份Kubernetes配置
backup_kubernetes() {
    log_info "备份Kubernetes配置..."
    
    # 备份集群配置
    kubectl get all --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/all-resources.yaml"
    kubectl get configmaps --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/configmaps.yaml"
    kubectl get secrets --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/secrets.yaml"
    kubectl get services --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/services.yaml"
    kubectl get ingress --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/ingress.yaml"
    kubectl get persistentvolumes -o yaml > "${BACKUP_PATH}/kubernetes/persistentvolumes.yaml"
    kubectl get persistentvolumeclaims --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/persistentvolumeclaims.yaml"
    kubectl get storageclasses -o yaml > "${BACKUP_PATH}/kubernetes/storageclasses.yaml"
    kubectl get networkpolicies --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/networkpolicies.yaml"
    kubectl get podsecuritypolicies --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/podsecuritypolicies.yaml"
    kubectl get roles --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/roles.yaml"
    kubectl get rolebindings --all-namespaces -o yaml > "${BACKUP_PATH}/kubernetes/rolebindings.yaml"
    kubectl get clusterroles -o yaml > "${BACKUP_PATH}/kubernetes/clusterroles.yaml"
    kubectl get clusterrolebindings -o yaml > "${BACKUP_PATH}/kubernetes/clusterrolebindings.yaml"
    
    # 备份节点信息
    kubectl get nodes -o yaml > "${BACKUP_PATH}/kubernetes/nodes.yaml"
    
    # 备份命名空间
    kubectl get namespaces -o yaml > "${BACKUP_PATH}/kubernetes/namespaces.yaml"
    
    log_success "Kubernetes配置备份完成"
}

# 备份监控数据
backup_monitoring() {
    log_info "备份监控数据..."
    
    # 备份Prometheus配置
    if [ -f "/etc/prometheus/prometheus.yml" ]; then
        cp /etc/prometheus/prometheus.yml "${BACKUP_PATH}/monitoring/prometheus.yml"
    fi
    
    # 备份Prometheus数据
    if [ -d "/var/lib/prometheus" ]; then
        tar -czf "${BACKUP_PATH}/monitoring/prometheus-data.tar.gz" -C /var/lib prometheus
    fi
    
    # 备份Grafana配置
    if [ -f "/etc/grafana/grafana.ini" ]; then
        cp /etc/grafana/grafana.ini "${BACKUP_PATH}/monitoring/grafana.ini"
    fi
    
    # 备份Grafana数据
    if [ -d "/var/lib/grafana" ]; then
        tar -czf "${BACKUP_PATH}/monitoring/grafana-data.tar.gz" -C /var/lib grafana
    fi
    
    # 备份Alertmanager配置
    if [ -f "/etc/alertmanager/alertmanager.yml" ]; then
        cp /etc/alertmanager/alertmanager.yml "${BACKUP_PATH}/monitoring/alertmanager.yml"
    fi
    
    # 备份Alertmanager数据
    if [ -d "/var/lib/alertmanager" ]; then
        tar -czf "${BACKUP_PATH}/monitoring/alertmanager-data.tar.gz" -C /var/lib alertmanager
    fi
    
    log_success "监控数据备份完成"
}

# 备份CI/CD数据
backup_cicd() {
    log_info "备份CI/CD数据..."
    
    # 备份GitLab配置
    if [ -f "/etc/gitlab/gitlab.rb" ]; then
        cp /etc/gitlab/gitlab.rb "${BACKUP_PATH}/cicd/gitlab.rb"
    fi
    
    # 备份GitLab数据
    if [ -d "/var/opt/gitlab" ]; then
        tar -czf "${BACKUP_PATH}/cicd/gitlab-data.tar.gz" -C /var/opt gitlab
    fi
    
    # 备份Jenkins配置
    if [ -d "/var/lib/jenkins" ]; then
        tar -czf "${BACKUP_PATH}/cicd/jenkins-data.tar.gz" -C /var/lib jenkins
    fi
    
    # 备份Harbor配置
    if [ -f "/opt/harbor/harbor.yml" ]; then
        cp /opt/harbor/harbor.yml "${BACKUP_PATH}/cicd/harbor.yml"
    fi
    
    # 备份Harbor数据
    if [ -d "/data" ]; then
        tar -czf "${BACKUP_PATH}/cicd/harbor-data.tar.gz" -C / data
    fi
    
    log_success "CI/CD数据备份完成"
}

# 备份应用数据
backup_applications() {
    log_info "备份应用数据..."
    
    # 备份应用配置
    kubectl get configmaps -n production -o yaml > "${BACKUP_PATH}/applications/production-configmaps.yaml"
    kubectl get secrets -n production -o yaml > "${BACKUP_PATH}/applications/production-secrets.yaml"
    kubectl get deployments -n production -o yaml > "${BACKUP_PATH}/applications/production-deployments.yaml"
    kubectl get services -n production -o yaml > "${BACKUP_PATH}/applications/production-services.yaml"
    kubectl get ingress -n production -o yaml > "${BACKUP_PATH}/applications/production-ingress.yaml"
    kubectl get hpa -n production -o yaml > "${BACKUP_PATH}/applications/production-hpa.yaml"
    kubectl get pdb -n production -o yaml > "${BACKUP_PATH}/applications/production-pdb.yaml"
    
    # 备份应用日志
    if kubectl get pods -n production -l app=web-app >/dev/null 2>&1; then
        kubectl logs -n production -l app=web-app --previous > "${BACKUP_PATH}/applications/web-app-logs.log" 2>/dev/null || true
    fi
    
    log_success "应用数据备份完成"
}

# 备份系统配置
backup_system() {
    log_info "备份系统配置..."
    
    # 备份系统配置文件
    cp /etc/hosts "${BACKUP_PATH}/system/hosts"
    cp /etc/resolv.conf "${BACKUP_PATH}/system/resolv.conf"
    cp /etc/sysctl.conf "${BACKUP_PATH}/system/sysctl.conf"
    cp /etc/security/limits.conf "${BACKUP_PATH}/system/limits.conf"
    cp /etc/fstab "${BACKUP_PATH}/system/fstab"
    
    # 备份网络配置
    if [ -f "/etc/sysconfig/network-scripts/ifcfg-eth0" ]; then
        cp /etc/sysconfig/network-scripts/ifcfg-eth0 "${BACKUP_PATH}/system/ifcfg-eth0"
    fi
    
    # 备份防火墙配置
    firewall-cmd --list-all > "${BACKUP_PATH}/system/firewall-rules.txt"
    
    # 备份Docker配置
    if [ -f "/etc/docker/daemon.json" ]; then
        cp /etc/docker/daemon.json "${BACKUP_PATH}/system/docker-daemon.json"
    fi
    
    # 备份Kubernetes配置
    if [ -f "/etc/kubernetes/admin.conf" ]; then
        cp /etc/kubernetes/admin.conf "${BACKUP_PATH}/system/kubeconfig"
    fi
    
    # 备份服务配置
    systemctl list-unit-files --type=service > "${BACKUP_PATH}/system/services.txt"
    
    # 备份软件包列表
    rpm -qa > "${BACKUP_PATH}/system/installed-packages.txt"
    
    # 备份系统信息
    uname -a > "${BACKUP_PATH}/system/system-info.txt"
    cat /etc/os-release >> "${BACKUP_PATH}/system/system-info.txt"
    lscpu >> "${BACKUP_PATH}/system/system-info.txt"
    free -h >> "${BACKUP_PATH}/system/system-info.txt"
    df -h >> "${BACKUP_PATH}/system/system-info.txt"
    
    log_success "系统配置备份完成"
}

# 压缩备份文件
compress_backup() {
    log_info "压缩备份文件..."
    
    cd "${BACKUP_DIR}"
    tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
    rm -rf "${BACKUP_NAME}"
    
    log_success "备份文件压缩完成: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    
    # 保留最近7天的备份
    find "${BACKUP_DIR}" -name "devops-platform-backup-*.tar.gz" -mtime +7 -delete
    
    log_success "旧备份文件清理完成"
}

# 验证备份
verify_backup() {
    log_info "验证备份文件..."
    
    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" ]; then
        local backup_size=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
        log_success "备份文件验证成功，大小: ${backup_size}"
        return 0
    else
        log_error "备份文件验证失败"
        return 1
    fi
}

# 生成备份报告
generate_report() {
    log_info "生成备份报告..."
    
    cat > "${BACKUP_PATH}/backup-report.md" << EOF
# 云原生DevOps平台备份报告

## 备份信息
- 备份时间: $(date)
- 备份名称: ${BACKUP_NAME}
- 备份路径: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz
- 备份大小: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

## 备份内容
- Kubernetes配置: 集群配置、资源定义、RBAC配置
- 监控数据: Prometheus、Grafana、Alertmanager配置和数据
- CI/CD数据: GitLab、Jenkins、Harbor配置和数据
- 应用数据: 应用配置、日志、资源定义
- 系统配置: 系统文件、网络配置、服务配置

## 恢复说明
1. 解压备份文件: tar -xzf ${BACKUP_NAME}.tar.gz
2. 恢复Kubernetes配置: kubectl apply -f kubernetes/
3. 恢复监控数据: 复制配置文件到相应目录
4. 恢复CI/CD数据: 复制配置文件到相应目录
5. 恢复应用数据: kubectl apply -f applications/
6. 恢复系统配置: 复制配置文件到相应目录

## 注意事项
- 恢复前请确保目标环境与备份环境兼容
- 恢复后请验证所有服务状态
- 建议在恢复前备份当前环境
- 恢复过程中可能需要重启相关服务

## 联系信息
如有问题，请联系系统管理员。
EOF
    
    log_success "备份报告已生成: ${BACKUP_PATH}/backup-report.md"
}

# 主函数
main() {
    log_info "开始云原生DevOps平台备份..."
    echo "========================================"
    
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请以root用户运行此脚本"
        exit 1
    fi
    
    # 检查必要命令
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl命令未找到"
        exit 1
    fi
    
    # 执行备份
    create_backup_dir
    backup_kubernetes
    backup_monitoring
    backup_cicd
    backup_applications
    backup_system
    compress_backup
    cleanup_old_backups
    verify_backup
    generate_report
    
    log_success "备份完成！"
    log_info "备份文件: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    log_info "备份报告: ${BACKUP_PATH}/backup-report.md"
    echo "========================================"
}

# 执行主函数
main "$@"
