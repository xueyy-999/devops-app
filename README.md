# Cloud-Native DevOps Platform

A fully automated cloud-native DevOps platform deployment solution based on Ansible, supporting single-node and multi-node deployments.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-CentOS%209-orange.svg)](https://www.centos.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue.svg)](https://kubernetes.io/)

## Overview

This project provides a complete cloud-native DevOps platform with automated deployment capabilities:

- **Container Orchestration**: Kubernetes 1.28 cluster
- **Container Runtime**: Docker + Containerd
- **CI/CD Pipeline**: GitLab + Jenkins + Harbor
- **Monitoring Stack**: Prometheus + Grafana + Alertmanager
- **Infrastructure as Code**: Ansible automation

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Cloud-Native DevOps Platform            │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   CI/CD      │  │  Monitoring  │  │ Applications │  │
│  │  GitLab      │  │  Prometheus  │  │  Web Apps    │  │
│  │  Jenkins     │  │  Grafana     │  │  Microservices│  │
│  │  Harbor      │  │  Alertmanager│  │  API Gateway │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│              Kubernetes Orchestration Layer             │
├─────────────────────────────────────────────────────────┤
│              Docker/Containerd Runtime                  │
├─────────────────────────────────────────────────────────┤
│              CentOS 9 Stream                            │
└─────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Version | Description |
|-----------|---------|-------------|
| Kubernetes | 1.28.0 | Container orchestration |
| Docker | 24.0+ | Container runtime |
| GitLab | 16.0.0 | Source code management |
| Jenkins | 2.401+ | CI/CD automation |
| Harbor | 2.8.0 | Container registry |
| Prometheus | 2.45+ | Metrics & monitoring |
| Grafana | 10.0+ | Visualization |
| Ansible | 2.9+ | Infrastructure automation |

## Quick Start

### Option 1: Docker Compose (Development)

```bash
# Start the platform
docker compose up -d

# Start demo application
cd demo-app && docker-compose up -d
```

**Access Services:**
- Demo App: http://localhost:8888
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin123)
- Jenkins: http://localhost:8080

### Option 2: Ansible Deployment (Production)

**Prerequisites:**
- CentOS 9 Stream
- 8GB+ RAM (16GB recommended)
- 50GB+ disk space
- Python 3.6+, Ansible 2.9+

**Deploy:**

```bash
# 1. Clone repository
git clone https://github.com/xueyy-999/devops-app.git
cd devops-app

# 2. Install Ansible
./install-ansible.sh

# 3. Configure inventory
cp inventory/single-node.yml.example inventory/single-node.yml
vim inventory/single-node.yml

# 4. Run deployment
ansible-playbook -i inventory/single-node.yml site.yml
```

**Or step-by-step:**

```bash
ansible-playbook -i inventory/single-node.yml playbooks/01-common-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/02-docker-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/03-kubernetes-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/04-monitoring-setup.yml
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml
```

## Project Structure

```
devops-app/
├── ansible.cfg              # Ansible configuration
├── docker-compose.yml       # Platform services
├── Jenkinsfile              # CI/CD pipeline
├── site.yml                 # Main deployment playbook
├── inventory/               # Host inventory
│   ├── hosts.yml
│   └── single-node.yml
├── playbooks/               # Ansible playbooks
│   ├── 01-common-setup.yml
│   ├── 02-docker-setup.yml
│   ├── 03-kubernetes-setup.yml
│   ├── 04-monitoring-setup.yml
│   └── 05-cicd-setup.yml
├── demo-app/                # Demo application
│   ├── backend/             # Flask REST API
│   ├── frontend/            # Nginx + Static files
│   ├── k8s/                 # Kubernetes manifests
│   ├── Jenkinsfile          # App CI/CD pipeline
│   └── docker-compose.yml
├── scripts/                 # Utility scripts
│   ├── health-check.sh
│   ├── backup.sh
│   └── verify-platform.sh
├── templates/               # Jinja2 templates
└── docs/                    # Documentation
```

## Demo Application

The included demo application demonstrates a complete CI/CD workflow:

- **Frontend**: HTML/CSS/JS with Nginx
- **Backend**: Flask REST API
- **Database**: PostgreSQL
- **Cache**: Redis

```bash
cd demo-app
docker-compose up -d
# Access: http://localhost:8888
```

## Operations

```bash
# Health check
./scripts/health-check.sh

# Backup
./scripts/backup.sh

# Platform verification
./scripts/verify-platform.sh
```

## Documentation

- [Configuration Guide](docs/CONFIGURATION.md)
- [Single-Node Deployment](docs/single-node-deployment.md)
- [Project Structure](docs/PROJECT_STRUCTURE.md)
- [Contributing](docs/CONTRIBUTING.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**xueyy-999** - [GitHub](https://github.com/xueyy-999)
