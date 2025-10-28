# 项目结构说明

本文档详细说明项目的目录结构和各文件的作用。

## 目录结构

```
cloud-native-devops-platform/
│
├── README.md                           # 项目主文档
├── ansible.cfg                         # Ansible 配置文件
├── site.yml                            # Ansible 主 Playbook
│
├── docs/                               # 文档目录
│   ├── quick-start.md                 # 快速开始指南
│   ├── deployment-guide.md            # 详细部署指南
│   ├── single-node-deployment.md      # 单节点部署说明
│   ├── kubernetes-fix-guide.md        # Kubernetes 问题修复
│   ├── technical-architecture.md      # 技术架构设计
│   ├── PROJECT_STRUCTURE.md           # 本文档
│   └── README-original.md             # 原始 README 备份
│
├── inventory/                          # Ansible 清单文件
│   ├── hosts.yml                      # 多节点集群配置
│   │   ├── [control_nodes]            # 控制节点组
│   │   ├── [compute_nodes]            # 计算节点组
│   │   ├── [storage_nodes]            # 存储节点组
│   │   ├── [monitoring_nodes]         # 监控节点组
│   │   └── [cicd_nodes]               # CI/CD 节点组
│   └── single-node.yml                # 单节点配置
│
├── playbooks/                          # Ansible Playbook 目录
│   ├── 01-common-setup.yml            # 基础环境配置
│   │   ├── 系统参数优化
│   │   ├── 防火墙配置
│   │   ├── 时间同步
│   │   └── 内核参数调整
│   │
│   ├── 02-docker-setup.yml            # Docker 安装和配置
│   │   ├── Docker CE 安装
│   │   ├── Docker 配置文件
│   │   ├── Docker 存储驱动
│   │   └── Docker 镜像加速
│   │
│   ├── 03-kubernetes-fixed.yml        # Kubernetes 集群部署
│   │   ├── kubeadm 安装
│   │   ├── 集群初始化
│   │   ├── CNI 网络插件（Flannel）
│   │   ├── Worker 节点加入
│   │   └── RBAC 配置
│   │
│   ├── 04-monitoring-setup.yml        # 监控系统部署
│   │   ├── Prometheus 安装
│   │   ├── Grafana 安装
│   │   ├── Alertmanager 配置
│   │   ├── Node Exporter 部署
│   │   └── 监控面板导入
│   │
│   ├── 04-monitoring-docker.yml       # Docker 方式部署监控
│   │   └── 使用 Docker Compose 部署监控栈
│   │
│   ├── 05-cicd-setup.yml              # CI/CD 系统部署
│   │   ├── GitLab 安装
│   │   ├── GitLab Runner 配置
│   │   ├── Jenkins 安装
│   │   ├── Harbor 镜像仓库
│   │   └── Pipeline 配置
│   │
│   ├── 06-application-deploy.yml      # 示例应用部署
│   │   ├── Namespace 创建
│   │   ├── Deployment 部署
│   │   ├── Service 创建
│   │   ├── Ingress 配置
│   │   ├── HPA 自动扩缩容
│   │   └── ConfigMap/Secret 管理
│   │
│   ├── 07-verification.yml            # 系统验证
│   │   ├── 集群健康检查
│   │   ├── 服务可用性测试
│   │   ├── 网络连通性测试
│   │   └── 生成验证报告
│   │
│   └── single-node-deploy.yml         # 单节点完整部署
│       └── 整合上述所有步骤用于单节点
│
├── templates/                          # Jinja2 模板文件
│   │
│   ├── 系统配置模板
│   │   ├── chrony.conf.j2             # 时间同步配置
│   │   ├── daemon.json.j2             # Docker 配置
│   │   └── docker-logrotate.j2        # Docker 日志轮转
│   │
│   ├── Kubernetes 配置模板
│   │   ├── kubeadm-config.yaml.j2     # kubeadm 初始化配置
│   │   ├── kubelet-config.yaml.j2     # kubelet 配置
│   │   ├── kubelet.service.j2         # kubelet systemd 服务
│   │   ├── containerd.toml.j2         # containerd 配置
│   │   └── rbac-config.yaml.j2        # RBAC 权限配置
│   │
│   ├── 监控配置模板
│   │   ├── prometheus.yml.j2          # Prometheus 配置
│   │   ├── prometheus.service.j2      # Prometheus systemd 服务
│   │   ├── alertmanager.yml.j2        # Alertmanager 配置
│   │   ├── alertmanager.service.j2    # Alertmanager systemd 服务
│   │   ├── grafana.ini.j2             # Grafana 配置
│   │   ├── node_exporter.service.j2   # Node Exporter 服务
│   │   ├── k8s-prometheus-config.yaml.j2    # K8s 中的 Prometheus 配置
│   │   ├── k8s-grafana-config.yaml.j2       # K8s 中的 Grafana 配置
│   │   ├── k8s-alertmanager-config.yaml.j2  # K8s 中的 Alertmanager 配置
│   │   ├── k8s-node-exporter.yaml.j2        # K8s 中的 Node Exporter
│   │   └── k8s-servicemonitor.yaml.j2       # ServiceMonitor CRD
│   │
│   ├── CI/CD 配置模板
│   │   ├── gitlab.rb.j2               # GitLab 配置
│   │   ├── gitlab-runner.yaml.j2      # GitLab Runner 配置
│   │   ├── jenkins.service.j2         # Jenkins 服务
│   │   ├── jenkins-agent.yaml.j2      # Jenkins Agent 配置
│   │   ├── harbor.yml.j2              # Harbor 配置
│   │   ├── pipeline-config.yaml.j2    # Pipeline 配置
│   │   └── cicd-rbac.yaml.j2          # CI/CD RBAC 配置
│   │
│   ├── 应用部署模板
│   │   ├── app-deployment.yaml.j2     # Deployment 配置
│   │   ├── app-service.yaml.j2        # Service 配置
│   │   ├── app-ingress.yaml.j2        # Ingress 配置
│   │   ├── app-configmap.yaml.j2      # ConfigMap 配置
│   │   ├── app-secret.yaml.j2         # Secret 配置
│   │   ├── app-hpa.yaml.j2            # HPA 配置
│   │   └── app-pdb.yaml.j2            # PodDisruptionBudget 配置
│   │
│   ├── AI 扩缩容模板
│   │   ├── ai-scaler.yaml.j2          # AI Scaler Deployment
│   │   ├── ai-scaler-config.yaml.j2   # AI Scaler 配置
│   │   └── ai-scaler-service.yaml.j2  # AI Scaler Service
│   │
│   ├── 存储配置模板
│   │   └── local-storage-class.yaml.j2 # 本地存储类
│   │
│   ├── 网络配置模板
│   │   └── nginx.conf.j2               # Nginx 配置
│   │
│   └── 其他配置模板
│       ├── redis.conf.j2               # Redis 配置
│       └── verification-report.j2      # 验证报告模板
│
├── scripts/                            # 辅助脚本目录
│   ├── backup.sh                      # 备份脚本
│   │   ├── 备份 Kubernetes 配置
│   │   ├── 备份应用数据
│   │   └── 备份监控配置
│   │
│   ├── health-check.sh                # 健康检查脚本
│   │   ├── 检查服务状态
│   │   ├── 检查资源使用
│   │   └── 生成健康报告
│   │
│   └── quick-verify.sh                # 快速验证脚本
│       ├── 验证集群状态
│       ├── 验证服务可用性
│       └── 输出验证结果
│
├── 部署脚本
│   ├── deploy.sh                      # 主部署脚本（多节点）
│   │   ├── 参数解析
│   │   ├── 环境检查
│   │   ├── 执行部署
│   │   └── 部署验证
│   │
│   ├── deploy-single.sh               # 单节点部署脚本
│   │   └── 单机环境快速部署
│   │
│   ├── deploy-kubernetes-simple.sh    # 简化的 K8s 部署脚本
│   │   └── 仅部署 Kubernetes 集群
│   │
│   └── fix-kubernetes-repo.sh         # Kubernetes 仓库修复脚本
│       └── 修复仓库访问问题
│
└── 配置文件
    └── ansible.cfg                     # Ansible 配置
        ├── 连接配置
        ├── 权限提升
        ├── 日志配置
        └── 插件路径

```

## 文件说明

### 核心文件

#### README.md
项目主文档，包含：
- 项目简介
- 快速开始指南
- 功能特性
- 访问地址
- 故障排除

#### site.yml
Ansible 主 Playbook，定义：
- 部署流程
- 变量配置
- 任务编排
- 部署模式

#### ansible.cfg
Ansible 配置文件，设置：
- SSH 连接参数
- 权限提升方式
- 日志输出
- 插件路径

### Inventory 清单

#### hosts.yml (多节点配置)
定义集群节点分组：
- `control_nodes`: Kubernetes 控制平面节点
- `compute_nodes`: Kubernetes 工作节点
- `storage_nodes`: 存储节点（可选）
- `monitoring_nodes`: 监控系统节点
- `cicd_nodes`: CI/CD 系统节点

示例配置：
```yaml
all:
  children:
    control_nodes:
      hosts:
        master-01:
          ansible_host: 192.168.1.10
          ansible_user: root
    compute_nodes:
      hosts:
        worker-01:
          ansible_host: 192.168.1.20
          ansible_user: root
```

#### single-node.yml (单节点配置)
单机环境配置：
- 所有组件部署在同一节点
- 适用于测试和学习
- 资源要求较低

### Playbooks 说明

#### 01-common-setup.yml
基础环境配置，包括：
- 系统软件包安装
- 内核参数优化
- 防火墙规则配置
- 时间同步设置
- SELinux 配置
- Swap 禁用

#### 02-docker-setup.yml
Docker 安装和配置：
- Docker CE 安装
- Docker daemon 配置
- 镜像加速器设置
- 日志驱动配置
- 存储驱动优化

#### 03-kubernetes-fixed.yml
Kubernetes 集群部署：
- 仓库配置（修复版）
- kubeadm/kubelet/kubectl 安装
- 控制平面初始化
- CNI 网络插件部署
- Worker 节点加入
- kubectl 配置

#### 04-monitoring-setup.yml
监控系统部署：
- Prometheus 安装配置
- Grafana 安装配置
- Alertmanager 告警配置
- Node Exporter 部署
- 监控面板导入
- 告警规则配置

#### 05-cicd-setup.yml
CI/CD 系统部署：
- GitLab 安装
- GitLab Runner 配置
- Jenkins 安装
- Harbor 镜像仓库
- Pipeline 配置

#### 06-application-deploy.yml
示例应用部署：
- Namespace 创建
- Deployment 部署
- Service 暴露
- Ingress 配置
- ConfigMap/Secret 管理
- HPA 自动扩缩容

#### 07-verification.yml
系统验证：
- 集群状态检查
- Pod 状态验证
- 服务连通性测试
- 生成验证报告

### 模板文件

所有 `.j2` 文件都是 Jinja2 模板，Ansible 会根据变量渲染生成最终配置文件。

模板变量通常在以下位置定义：
- `site.yml` 中的 `vars` 部分
- `inventory/hosts.yml` 中的主机变量
- `playbooks/*.yml` 中的任务变量

### 脚本文件

#### backup.sh
自动备份脚本，备份内容：
- Kubernetes 集群配置
- 应用配置和数据
- 监控配置和数据
- 证书文件

#### health-check.sh
健康检查脚本，检查项：
- 服务运行状态
- 资源使用情况
- 网络连通性
- 存储状态

#### quick-verify.sh
快速验证脚本，验证：
- 集群节点状态
- 核心 Pod 运行状态
- 基本服务可用性

### 部署脚本

#### deploy.sh
主部署脚本，支持：
- 多种部署模式（full/minimal/custom）
- 标签选择
- 检查模式
- 详细日志

#### deploy-single.sh
单节点部署脚本，特点：
- 简化配置
- 快速部署
- 适合测试环境

## 使用流程

### 1. 准备阶段
```bash
# 配置服务器清单
vim inventory/hosts.yml

# 配置 SSH 密钥认证
ssh-copy-id root@<target-host>
```

### 2. 部署阶段
```bash
# 完整部署
./deploy.sh --mode full

# 或分步部署
./deploy.sh --tags setup,common    # 基础配置
./deploy.sh --tags docker           # Docker 安装
./deploy.sh --tags kubernetes       # K8s 集群
./deploy.sh --tags monitoring       # 监控系统
./deploy.sh --tags cicd             # CI/CD 系统
./deploy.sh --tags application      # 应用部署
```

### 3. 验证阶段
```bash
# 快速验证
./scripts/quick-verify.sh

# 完整验证
ansible-playbook -i inventory/hosts.yml playbooks/07-verification.yml
```

### 4. 运维阶段
```bash
# 健康检查
./scripts/health-check.sh

# 数据备份
./scripts/backup.sh
```

## 自定义扩展

### 添加新节点

1. 在 `inventory/hosts.yml` 中添加节点信息
2. 执行部署脚本：
```bash
./deploy.sh --tags setup,common,docker,kubernetes --limit new-node
```

### 添加新应用

1. 在 `templates/` 中创建应用模板
2. 在 `playbooks/06-application-deploy.yml` 中添加部署任务
3. 执行部署：
```bash
./deploy.sh --tags application
```

### 自定义监控

1. 修改 `templates/prometheus.yml.j2` 添加监控目标
2. 在 `templates/` 中添加 Grafana 面板 JSON
3. 重新部署监控：
```bash
./deploy.sh --tags monitoring
```

## 最佳实践

1. **版本控制**: 使用 Git 管理配置变更
2. **备份**: 定期执行 `backup.sh` 备份重要数据
3. **测试**: 在测试环境验证后再部署到生产
4. **日志**: 保留部署日志以便问题追踪
5. **文档**: 记录自定义配置和变更

## 注意事项

1. **权限**: 确保有足够的权限执行部署操作
2. **网络**: 确保节点间网络互通
3. **资源**: 确保节点满足最低资源要求
4. **兼容性**: 确认操作系统版本兼容
5. **安全**: 及时更新密码和证书

## 相关文档

- [快速开始指南](quick-start.md)
- [详细部署指南](deployment-guide.md)
- [Kubernetes 问题修复](kubernetes-fix-guide.md)
- [技术架构设计](technical-architecture.md)

