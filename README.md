# 云原生DevOps平台 🚀

基于Ansible的全自动化云原生DevOps平台部署方案，支持单节点和多节点部署。

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-CentOS%209-orange.svg)](https://www.centos.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue.svg)](https://kubernetes.io/)
[![GitLab](https://img.shields.io/badge/GitLab-16.0-orange.svg)](https://gitlab.com/)

## 📋 项目简介

这是一个完整的云原生DevOps平台自动化部署项目，包含：

- ✅ **容器编排**: Kubernetes 1.28 集群
- ✅ **容器运行时**: Docker + Containerd
- ✅ **CI/CD**: GitLab + Jenkins + Harbor
- ✅ **监控系统**: Prometheus + Grafana + Alertmanager
- ✅ **日志管理**: 集中式日志收集
- ✅ **自动化部署**: 完全基于Ansible自动化

## 🏗️ 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                   云原生DevOps平台                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   CI/CD层    │  │   监控层     │  │   应用层     │ │
│  │              │  │              │  │              │ │
│  │  GitLab      │  │  Prometheus  │  │  Web Apps    │ │
│  │  Jenkins     │  │  Grafana     │  │  Microservices│ │
│  │  Harbor      │  │  Alertmanager│  │  API Gateway │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                Kubernetes容器编排层                      │
│        (Control Plane + Worker Nodes)                   │
├─────────────────────────────────────────────────────────┤
│              Docker/Containerd运行时                     │
├─────────────────────────────────────────────────────────┤
│              CentOS 9 Stream操作系统                     │
└─────────────────────────────────────────────────────────┘
```

## 🎯 功能特性

### 核心功能
- 🔄 **一键部署**: 完全自动化的Ansible playbook
- 🔍 **健康检查**: 内置诊断和修复脚本
- 📊 **资源监控**: 完整的Prometheus监控体系
- 🛡️ **安全加固**: SELinux配置、防火墙规则
- 📝 **日志管理**: 完整的日志收集和轮转
- 🔧 **故障修复**: 自动化的问题诊断和修复工具

### 支持的部署模式
- **单节点部署**: 适合开发/测试环境
- **多节点部署**: 适合生产环境
- **高可用部署**: 多Master节点（规划中）

## 📦 组件版本

| 组件 | 版本 | 说明 |
|------|------|------|
| CentOS | 9 Stream | 操作系统 |
| Kubernetes | 1.28.0 | 容器编排 |
| Docker | 24.0+ | 容器运行时 |
| GitLab | 16.0.0 | 代码仓库 |
| Jenkins | 2.401+ | CI/CD服务器 |
| Harbor | 2.8.0 | 镜像仓库 |
| Prometheus | 2.45+ | 监控系统 |
| Grafana | 10.0+ | 可视化仪表板 |

## 🚀 快速开始

### 前置要求

#### 硬件要求（单节点）
- **CPU**: 最少4核，推荐8核
- **内存**: 最少8GB，推荐16GB
- **磁盘**: 最少50GB，推荐100GB

#### 软件要求
- CentOS 9 Stream
- Python 3.6+
- Ansible 2.9+

### 安装步骤

#### 1. 克隆项目
```bash
git clone https://github.com/xueyy-999/demo-devops-app.git
cd demo-devops-app
```

#### 2. 安装Ansible
```bash
chmod +x install-ansible.sh
./install-ansible.sh
```

#### 3. 配置inventory
```bash
# 复制示例配置
cp inventory/single-node.yml.example inventory/single-node.yml

# 编辑配置，修改IP地址等信息
vim inventory/single-node.yml
```

#### 4. 运行预检查
```bash
# SELinux检查
ansible-playbook -i inventory/single-node.yml playbooks/00-selinux-check.yml

# 资源检查
ansible-playbook -i inventory/single-node.yml playbooks/00-resource-check.yml

# 系统预检查
./pre-check.sh
```

#### 5. 执行部署

**单节点快速部署**:
```bash
./deploy-single.sh
```

**或分步部署**:
```bash
# 1. 基础环境
ansible-playbook -i inventory/single-node.yml playbooks/01-common-setup.yml

# 2. Docker环境
ansible-playbook -i inventory/single-node.yml playbooks/02-docker-setup.yml

# 3. Kubernetes集群
ansible-playbook -i inventory/single-node.yml playbooks/03-kubernetes-fixed.yml

# 4. 监控系统
ansible-playbook -i inventory/single-node.yml playbooks/04-monitoring-setup.yml

# 5. CI/CD系统
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml

# 6. 应用部署（可选）
ansible-playbook -i inventory/single-node.yml playbooks/06-application-deploy.yml

# 7. 验证
ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml
```

## 🔧 故障排查

### GitLab 502错误
如果遇到GitLab 502错误，运行快速修复脚本：

```bash
chmod +x quick-fix-gitlab-502.sh
./quick-fix-gitlab-502.sh
```

### 完整诊断
```bash
chmod +x scripts/gitlab-diagnosis.sh
./scripts/gitlab-diagnosis.sh
```

### 查看详细文档
- [立即修复指南](IMMEDIATE_FIX_GUIDE.md)
- [完整问题分析](PROJECT_ISSUES_COMPLETE_ANALYSIS.md)
- [GitLab排查指南](GITLAB_TROUBLESHOOTING.md)

## 📖 文档

### 核心文档
- [快速开始](docs/quick-start.md)
- [配置说明](docs/CONFIGURATION.md)
- [单节点部署](docs/single-node-deployment.md)
- [项目结构](docs/PROJECT_STRUCTURE.md)

### 故障排查
- [立即修复指南](IMMEDIATE_FIX_GUIDE.md) ⭐ 推荐
- [完整问题分析](PROJECT_ISSUES_COMPLETE_ANALYSIS.md)
- [GitLab排查指南](GITLAB_TROUBLESHOOTING.md)
- [Nginx修复指南](NGINX_FIX_GUIDE.md)

### 修复工具
- `quick-fix-gitlab-502.sh` - GitLab 502自动修复
- `quick-fix-gitlab.sh` - GitLab通用修复
- `scripts/gitlab-diagnosis.sh` - 完整诊断工具
- `scripts/health-check.sh` - 健康检查
- `scripts/backup.sh` - 备份工具

## 🎮 访问地址

部署完成后，可以访问以下服务：

| 服务 | 地址 | 默认账号 |
|------|------|---------|
| Kubernetes Dashboard | `http://your-ip:30000` | 见部署日志 |
| GitLab | `http://your-ip/` | root / 见 `/etc/gitlab/initial_root_password` |
| Jenkins | `http://your-ip:8080` | admin / 见部署日志 |
| Harbor | `http://your-ip:5000` | admin / Harbor12345 |
| Prometheus | `http://your-ip:9090` | 无需认证 |
| Grafana | `http://your-ip:3000` | admin / 见部署日志 |

## 🛠️ 维护操作

### 备份
```bash
./scripts/backup.sh
```

### 健康检查
```bash
./scripts/health-check.sh
```

### 快速验证
```bash
./scripts/quick-verify.sh
```

### 查看日志
```bash
# GitLab日志
gitlab-ctl tail

# Kubernetes日志
kubectl logs -n kube-system <pod-name>

# 监控日志
docker logs prometheus
docker logs grafana
```

## 📂 项目结构

```
demo-devops-app/
├── ansible.cfg                 # Ansible配置
├── inventory/                  # 主机清单
│   ├── hosts.yml              # 多节点配置
│   └── single-node.yml        # 单节点配置
├── playbooks/                  # Ansible playbooks
│   ├── 00-selinux-check.yml   # SELinux检查
│   ├── 00-resource-check.yml  # 资源检查
│   ├── 01-common-setup.yml    # 基础环境
│   ├── 02-docker-setup.yml    # Docker安装
│   ├── 03-kubernetes-fixed.yml # K8s集群
│   ├── 04-monitoring-setup.yml # 监控系统
│   ├── 05-cicd-setup.yml      # CI/CD系统
│   ├── 06-application-deploy.yml # 应用部署
│   └── 07-verification.yml    # 验证脚本
├── templates/                  # Jinja2模板
├── scripts/                    # 辅助脚本
│   ├── gitlab-diagnosis.sh    # GitLab诊断
│   ├── health-check.sh        # 健康检查
│   └── backup.sh              # 备份脚本
├── docs/                       # 文档
├── quick-fix-gitlab-502.sh    # 502快速修复
└── deploy-single.sh           # 单节点部署脚本
```

## 🤝 贡献

欢迎贡献！请查看 [贡献指南](docs/CONTRIBUTING.md)。

### 贡献方式
1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📝 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本更新信息。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👥 作者

- **xueyy-999** - *初始工作* - [GitHub](https://github.com/xueyy-999)

## 🙏 致谢

- Kubernetes社区
- GitLab团队
- Prometheus项目
- Ansible社区

## 📞 支持

如果遇到问题：

1. 查看[故障排查文档](IMMEDIATE_FIX_GUIDE.md)
2. 运行诊断脚本：`./scripts/gitlab-diagnosis.sh`
3. 提交[Issue](https://github.com/xueyy-999/demo-devops-app/issues)

## ⭐ Star历史

如果这个项目对你有帮助，请给个Star ⭐

---

**注意**: 本项目主要用于学习和测试环境，生产环境使用请做好安全加固和性能优化。
