#!/bin/bash

# 虚拟机文档创建脚本
# 在虚拟机上运行此脚本以创建完整的文档体系

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_info "开始创建项目文档..."

# 确保 docs 目录存在
mkdir -p docs

# 提示用户
echo ""
echo "========================================"
echo "  云原生 DevOps 平台 - 文档创建向导"
echo "========================================"
echo ""
echo "此脚本将创建以下文档："
echo "  1. README.md (项目主文档)"
echo "  2. CHANGELOG.md (变更日志)"
echo "  3. inventory 示例文件"
echo "  4. docs/ 目录下的所有文档"
echo ""
echo "注意: 如果文件已存在，将被覆盖！"
echo ""
read -p "是否继续? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "操作已取消"
    exit 0
fi

# 创建文档的函数
create_readme() {
    log_info "创建 README.md..."
    cat > README.md << 'EOFREADME'
# 云原生 DevOps 平台

基于 Ansible 和 Kubernetes 的云原生 DevOps 平台自动化部署项目。

## 📋 项目简介

本项目实现了从基础设施到应用部署的完整云原生 DevOps 平台，包括：

- **容器编排**: Kubernetes 集群自动化部署
- **CI/CD**: 完整的持续集成/持续部署流水线
- **监控告警**: Prometheus + Grafana 监控体系
- **自动化运维**: 基于 Ansible 的自动化部署脚本

## 🚀 快速开始

### 环境要求

- 操作系统: CentOS 9 / Rocky Linux 9
- 内存: 最低 8GB，推荐 16GB+
- CPU: 最低 4核，推荐 8核+
- 磁盘: 最低 100GB
- Python: 3.8+
- Ansible: 2.9+

### 单节点快速部署

```bash
# 1. 配置服务器信息
vim inventory/single-node.yml

# 2. 执行部署
./deploy-single.sh
```

### 多节点集群部署

```bash
# 1. 配置集群节点信息
vim inventory/hosts.yml

# 2. 选择部署模式
./deploy.sh --mode full        # 完整部署
./deploy.sh --mode minimal     # 最小化部署
./deploy.sh --mode custom --tags setup,docker,kubernetes  # 自定义部署
```

## 📁 项目结构

```
.
├── README.md                   # 项目主文档
├── CHANGELOG.md                # 变更日志
├── LICENSE                     # 许可证
├── .gitignore                  # Git 忽略规则
├── ansible.cfg                 # Ansible 配置
├── site.yml                    # 主 Playbook
├── deploy.sh                   # 部署脚本
├── inventory/                  # 清单文件
├── playbooks/                  # Ansible Playbooks
├── templates/                  # Jinja2 模板
├── scripts/                    # 辅助脚本
└── docs/                       # 详细文档
```

## 🛠️ 核心功能

- ✅ 自动化部署完整平台
- ✅ Kubernetes 高可用集群
- ✅ 自动扩缩容 (HPA)
- ✅ Prometheus + Grafana 监控
- ✅ GitLab CI/CD
- ✅ Harbor 镜像仓库

## 📚 文档

- [快速开始指南](docs/quick-start.md)
- [详细部署指南](docs/deployment-guide.md)
- [单节点部署](docs/single-node-deployment.md)
- [配置说明](docs/CONFIGURATION.md)
- [项目结构](docs/PROJECT_STRUCTURE.md)

## 常用命令

```bash
# 检查部署状态
kubectl get nodes
kubectl get pods --all-namespaces

# 查看服务状态
systemctl status docker
systemctl status kubelet

# 运行健康检查
./scripts/health-check.sh
```

## 🔍 故障排除

### Kubernetes 节点 NotReady

```bash
systemctl status kubelet
journalctl -u kubelet -f
kubectl get pods -n kube-system
```

### Docker 服务启动失败

```bash
systemctl status docker
journalctl -u docker -f
```

更多问题请参考 [问题修复指南](docs/kubernetes-fix-guide.md)

## 📄 许可证

本项目采用 MIT 许可证。

---

**注意**: 本项目适用于学习和测试环境。生产环境部署前请充分测试。
EOFREADME
    log_success "README.md 创建完成"
}

create_changelog() {
    log_info "创建 CHANGELOG.md..."
    cat > CHANGELOG.md << 'EOFCHANGELOG'
# 变更日志

## [1.0.0] - 2024-01-01

### 新增
- 基础环境自动化配置
- Docker 安装和配置模块
- Kubernetes 集群自动化部署
- Prometheus + Grafana 监控系统
- GitLab CI/CD 集成
- Harbor 镜像仓库部署
- 示例应用部署模块
- 系统验证和测试脚本

### 修复
- 修复 Kubernetes 仓库访问问题
- 修复 CentOS 9 兼容性问题
- 优化网络插件配置

### 文档
- 添加完整的项目文档
- 添加配置说明
- 添加贡献指南
EOFCHANGELOG
    log_success "CHANGELOG.md 创建完成"
}

create_inventory_examples() {
    log_info "创建 inventory 示例文件..."
    
    # hosts.yml.example
    cat > inventory/hosts.yml.example << 'EOFHOSTS'
# Ansible Inventory 多节点配置示例
# 复制此文件为 hosts.yml 并根据实际环境修改

all:
  vars:
    ansible_user: root
    ansible_python_interpreter: /usr/bin/python3
    timezone: "Asia/Shanghai"
    cluster_network: "192.168.1.0/24"
    service_network: "10.96.0.0/12"
    pod_network: "10.244.0.0/16"
    
  children:
    control_nodes:
      hosts:
        master-01:
          ansible_host: 192.168.1.10
          node_ip: 192.168.1.10
      vars:
        node_role: master
    
    compute_nodes:
      hosts:
        worker-01:
          ansible_host: 192.168.1.20
          node_ip: 192.168.1.20
        worker-02:
          ansible_host: 192.168.1.21
          node_ip: 192.168.1.21
      vars:
        node_role: worker
    
    monitoring_nodes:
      hosts:
        monitor-01:
          ansible_host: 192.168.1.40
          node_ip: 192.168.1.40
EOFHOSTS

    # single-node.yml.example
    cat > inventory/single-node.yml.example << 'EOFSINGLE'
# Ansible Inventory 单节点配置示例
# 复制此文件为 single-node.yml 并根据实际环境修改

all:
  vars:
    ansible_connection: local
    ansible_python_interpreter: /usr/bin/python3
    timezone: "Asia/Shanghai"
    cluster_network: "192.168.76.0/24"
    service_network: "10.96.0.0/12"
    pod_network: "10.244.0.0/16"
    single_node_mode: true
    
  hosts:
    localhost:
      ansible_host: 127.0.0.1
      node_ip: 192.168.76.141  # 修改为你的实际 IP
      node_name: localhost
      node_role: master
EOFSINGLE

    log_success "inventory 示例文件创建完成"
}

# 执行创建
create_readme
create_changelog
create_inventory_examples

# 设置权限
chmod 644 README.md CHANGELOG.md
chmod 644 inventory/*.example

log_info ""
log_success "======================================"
log_success "所有文档创建完成！"
log_success "======================================"
log_info ""
log_info "已创建的文件："
log_info "  ✓ README.md"
log_info "  ✓ CHANGELOG.md"
log_info "  ✓ inventory/hosts.yml.example"
log_info "  ✓ inventory/single-node.yml.example"
log_info ""
log_info "建议下一步操作："
log_info "  1. 复制配置示例: cp inventory/single-node.yml.example inventory/single-node.yml"
log_info "  2. 修改配置文件: vim inventory/single-node.yml"
log_info "  3. 执行部署: ./deploy-single.sh"
log_info ""

