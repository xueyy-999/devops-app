# Cloud-Native DevOps Platform | 云原生 DevOps 平台

基于 Ansible 的全自动化云原生 DevOps 平台部署方案，支持单节点和多节点部署。

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-CentOS%209-orange.svg)](https://www.centos.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue.svg)](https://kubernetes.io/)

## 项目简介

本项目提供完整的云原生 DevOps 平台自动化部署能力：

- **容器编排**：Kubernetes 1.28 集群
- **容器运行时**：Docker + Containerd
- **CI/CD 流水线**：GitLab + Jenkins + Harbor
- **监控告警**：Prometheus + Grafana + Alertmanager
- **基础设施即代码**：Ansible 自动化部署

## 架构设计

```
┌─────────────────────────────────────────────────────────┐
│               Cloud-Native DevOps Platform              │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   CI/CD      │  │   监控告警   │  │   应用层     │  │
│  │  GitLab      │  │  Prometheus  │  │  Web Apps    │  │
│  │  Jenkins     │  │  Grafana     │  │  Microservices│  │
│  │  Harbor      │  │  Alertmanager│  │  API Gateway │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│              Kubernetes 容器编排层                       │
├─────────────────────────────────────────────────────────┤
│              Docker/Containerd 运行时                    │
├─────────────────────────────────────────────────────────┤
│              CentOS 9 Stream                            │
└─────────────────────────────────────────────────────────┘
```

## 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| Kubernetes | 1.28.0 | 容器编排 |
| Docker | 24.0+ | 容器运行时 |
| GitLab | 16.0.0 | 代码仓库 |
| Jenkins | 2.401+ | CI/CD 服务器 |
| Harbor | 2.8.0 | 镜像仓库 |
| Prometheus | 2.45+ | 监控系统 |
| Grafana | 10.0+ | 可视化仪表盘 |
| Ansible | 2.9+ | 自动化部署 |

## 快速开始

### 方式一：Docker Compose（开发环境）

```bash
# 启动平台服务
docker compose up -d

# 启动示例应用
cd demo-app && docker-compose up -d
```

**访问地址：**
- 示例应用：http://localhost:8888
- Prometheus：http://localhost:9090
- Grafana：http://localhost:3000 (admin/admin123)
- Jenkins：http://localhost:8080

### 方式二：Ansible 部署（生产环境）

**环境要求：**
- CentOS 9 Stream
- 8GB+ 内存（推荐 16GB）
- 50GB+ 磁盘空间
- Python 3.6+，Ansible 2.9+

**部署步骤：**

```bash
# 1. 克隆项目
git clone https://github.com/xueyy-999/devops-app.git
cd devops-app

# 2. 安装 Ansible
./install-ansible.sh

# 3. 配置主机清单
cp inventory/single-node.yml.example inventory/single-node.yml
vim inventory/single-node.yml

# 4. 执行部署
ansible-playbook -i inventory/single-node.yml site.yml
```

**分步部署：**

```bash
ansible-playbook -i inventory/single-node.yml playbooks/01-common-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/02-docker-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/03-kubernetes-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/04-monitoring-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml
```

## 项目结构

```
devops-app/
├── ansible.cfg              # Ansible 配置
├── docker-compose.yml       # 平台服务编排
├── Jenkinsfile              # CI/CD 流水线
├── site.yml                 # 主部署脚本
├── inventory/               # 主机清单
│   ├── hosts.yml
│   └── single-node.yml
├── playbooks/               # Ansible Playbooks
│   ├── 01-common-setup.yml
│   ├── 02-docker-setup.yml
│   ├── 03-kubernetes-setup.yml
│   ├── 04-monitoring-setup.yml
│   └── 05-cicd-setup.yml
├── demo-app/                # 示例应用
│   ├── backend/             # Flask 后端 API
│   ├── frontend/            # Nginx 前端
│   ├── k8s/                 # Kubernetes 配置
│   ├── Jenkinsfile          # 应用 CI/CD
│   └── docker-compose.yml
├── scripts/                 # 运维脚本
│   ├── health-check.sh
│   ├── backup.sh
│   └── verify-platform.sh
├── templates/               # Jinja2 模板
└── docs/                    # 文档
```

## 示例应用

项目包含完整的三层架构示例应用，用于演示 CI/CD 流程：

- **前端**：HTML/CSS/JS + Nginx
- **后端**：Flask REST API
- **数据库**：PostgreSQL
- **缓存**：Redis

```bash
cd demo-app
docker-compose up -d
# 访问：http://localhost:8888
```

## 运维操作

```bash
# 健康检查
./scripts/health-check.sh

# 数据备份
./scripts/backup.sh

# 平台验证
./scripts/verify-platform.sh
```

## 文档

- [配置说明](docs/CONFIGURATION.md)
- [单节点部署](docs/single-node-deployment.md)
- [项目结构](docs/PROJECT_STRUCTURE.md)
- [贡献指南](docs/CONTRIBUTING.md)

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 作者

**xueyy-999** - [GitHub](https://github.com/xueyy-999)
