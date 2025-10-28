# 云原生DevOps平台部署

基于OpenStack和Kubernetes的云原生DevOps平台自动化部署脚本。

## 项目概述

本项目实现了一个完整的云原生DevOps平台，包括：

- **基础设施层**: OpenStack云平台
- **容器编排层**: Kubernetes集群
- **应用交付层**: CI/CD流水线
- **监控运维层**: Prometheus + Grafana
- **智能运维层**: AI辅助扩缩容

## 系统架构

```
┌─────────────────────────────────────────┐
│           用户界面层 (UI Layer)          │
├─────────────────────────────────────────┤
│         应用服务层 (Service Layer)       │
│  ┌─────────────┐ ┌─────────────────────┐ │
│  │   CI/CD     │ │    监控告警系统      │ │
│  │   Pipeline  │ │  (Prometheus+Grafana)│ │
│  └─────────────┘ └─────────────────────┘ │
├─────────────────────────────────────────┤
│       容器编排层 (Orchestration Layer)   │
│            Kubernetes Cluster           │
├─────────────────────────────────────────┤
│      基础设施层 (Infrastructure Layer)   │
│              OpenStack Cloud            │
│  ┌─────┐ ┌─────────┐ ┌─────────┐ ┌─────┐ │
│  │Nova │ │Neutron  │ │ Cinder  │ │Key- │ │
│  │     │ │         │ │         │ │stone│ │
│  └─────┘ └─────────┘ └─────────┘ └─────┘ │
├─────────────────────────────────────────┤
│         物理资源层 (Hardware Layer)      │
│    计算节点 + 存储节点 + 网络设备        │
└─────────────────────────────────────────┘
```

## 功能特性

### 🚀 核心功能
- **自动化部署**: 一键部署完整的云原生平台
- **高可用设计**: 多节点部署，避免单点故障
- **弹性扩缩容**: 基于负载的自动扩缩容
- **监控告警**: 全栈监控和智能告警
- **CI/CD流水线**: 完整的自动化部署流水线

### 🔧 技术栈
- **容器化**: Docker + Kubernetes
- **监控**: Prometheus + Grafana + Alertmanager
- **CI/CD**: GitLab + Jenkins + Harbor
- **存储**: 本地存储 + 分布式存储
- **网络**: Flannel + Ingress
- **安全**: RBAC + TLS + 安全扫描

### 🤖 AI功能
- **智能扩缩容**: 基于机器学习的资源预测
- **异常检测**: 自动识别系统异常
- **根因分析**: 快速定位故障原因
- **自动化响应**: 基于规则的自动处理

## 快速开始

### 环境要求

- **操作系统**: CentOS 9
- **内存**: 最低 8GB，推荐 16GB
- **CPU**: 最低 4核，推荐 8核
- **磁盘**: 最低 100GB，推荐 500GB
- **网络**: 千兆网络

### 部署步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd cloud-native-devops-platform
```

2. **配置服务器清单**
编辑 `inventory/hosts.yml` 文件，配置你的服务器信息：

```yaml
all:
  children:
    control_nodes:
      hosts:
        control-01:
          ansible_host: 192.168.1.10
          ansible_user: root
        control-02:
          ansible_host: 192.168.1.11
          ansible_user: root
    compute_nodes:
      hosts:
        compute-01:
          ansible_host: 192.168.1.20
          ansible_user: root
        compute-02:
          ansible_host: 192.168.1.21
          ansible_user: root
    monitoring_nodes:
      hosts:
        monitor-01:
          ansible_host: 192.168.1.40
          ansible_user: root
    cicd_nodes:
      hosts:
        cicd-01:
          ansible_host: 192.168.1.50
          ansible_user: root
```

3. **执行部署**
```bash
# 完整部署
./deploy.sh --mode full

# 最小化部署
./deploy.sh --mode minimal

# 自定义部署
./deploy.sh --mode custom --tags setup,common,docker
```

4. **验证部署**
```bash
# 检查服务状态
kubectl get nodes
kubectl get pods --all-namespaces

# 访问应用
curl http://app.example.com
```

## 部署模式

### 完整部署 (full)
部署所有组件，包括：
- 基础环境配置
- Docker安装
- Kubernetes集群
- 监控系统
- CI/CD系统
- 示例应用

### 最小化部署 (minimal)
只部署核心组件：
- 基础环境配置
- Docker安装
- Kubernetes集群

### 自定义部署 (custom)
根据标签选择部署组件：
- `setup`: 基础配置
- `common`: 通用配置
- `docker`: Docker安装
- `kubernetes`: Kubernetes集群
- `monitoring`: 监控系统
- `cicd`: CI/CD系统
- `application`: 应用部署

## 配置说明

### 网络配置
```yaml
cluster_network: "192.168.1.0/24"    # 集群网络
service_network: "10.96.0.0/12"      # 服务网络
pod_network: "10.244.0.0/16"         # Pod网络
```

### 应用配置
```yaml
app_namespace: "production"           # 应用命名空间
app_name: "web-app"                   # 应用名称
app_replicas: 3                       # 副本数
app_domain: "app.example.com"         # 应用域名
```

### 监控配置
```yaml
prometheus_port: 9090                 # Prometheus端口
grafana_port: 3000                    # Grafana端口
alertmanager_port: 9093               # Alertmanager端口
```

## 访问地址

部署完成后，可以通过以下地址访问各个服务：

- **应用地址**: http://app.example.com
- **监控地址**: http://<ip>:9090
- **仪表板**: http://<ip>:3000
- **GitLab**: http://<ip>:80
- **Jenkins**: http://<ip>:8080
- **Harbor**: http://<ip>:80

## 常用命令

### 系统管理
```bash
# 检查服务状态
systemctl status docker
systemctl status kubelet

# 查看日志
journalctl -u docker -f
journalctl -u kubelet -f

# 重启服务
systemctl restart docker
systemctl restart kubelet
```

### Kubernetes管理
```bash
# 查看节点状态
kubectl get nodes -o wide

# 查看Pod状态
kubectl get pods --all-namespaces

# 查看服务状态
kubectl get services --all-namespaces

# 查看Ingress状态
kubectl get ingress --all-namespaces
```

### 监控管理
```bash
# 检查Prometheus状态
curl http://localhost:9090/api/v1/query?query=up

# 检查Grafana状态
curl http://localhost:3000/api/health

# 检查Alertmanager状态
curl http://localhost:9093/api/v1/status
```

## 故障排除

### 常见问题

1. **Docker服务启动失败**
```bash
# 检查Docker状态
systemctl status docker
journalctl -u docker -f

# 重启Docker服务
systemctl restart docker
```

2. **Kubernetes节点NotReady**
```bash
# 检查kubelet状态
systemctl status kubelet
journalctl -u kubelet -f

# 检查网络配置
kubectl get nodes -o wide
```

3. **Pod启动失败**
```bash
# 查看Pod详情
kubectl describe pod <pod-name> -n <namespace>

# 查看Pod日志
kubectl logs <pod-name> -n <namespace>
```

4. **网络连接问题**
```bash
# 检查网络连接
ping <target-ip>
telnet <target-ip> <port>

# 检查防火墙状态
firewall-cmd --list-all
```

### 日志位置

- **系统日志**: `/var/log/messages`
- **Docker日志**: `journalctl -u docker`
- **Kubernetes日志**: `journalctl -u kubelet`
- **应用日志**: `kubectl logs <pod-name>`

## 性能优化

### 系统优化
```bash
# 调整内核参数
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# 优化文件描述符限制
echo '* soft nofile 65536' >> /etc/security/limits.conf
echo '* hard nofile 65536' >> /etc/security/limits.conf
```

### Kubernetes优化
```yaml
# 资源配置
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 安全配置

### 网络安全
```bash
# 配置防火墙规则
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250-10252/tcp
firewall-cmd --reload
```

### 访问控制
```yaml
# RBAC配置
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

## 备份与恢复

### 数据备份
```bash
# 备份Kubernetes配置
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# 备份应用数据
kubectl get configmaps --all-namespaces -o yaml > configmaps-backup.yaml
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

### 数据恢复
```bash
# 恢复Kubernetes配置
kubectl apply -f k8s-backup.yaml

# 恢复应用数据
kubectl apply -f configmaps-backup.yaml
kubectl apply -f secrets-backup.yaml
```

## 扩展功能

### 添加新节点
```bash
# 添加工作节点
kubectl get nodes
kubectl taint nodes <node-name> node-role.kubernetes.io/worker:NoSchedule-
```

### 配置存储类
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目链接: [https://github.com/your-username/cloud-native-devops-platform](https://github.com/your-username/cloud-native-devops-platform)
- 问题反馈: [Issues](https://github.com/your-username/cloud-native-devops-platform/issues)
- 邮箱: your-email@example.com

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持完整的云原生DevOps平台部署
- 包含监控、CI/CD、应用部署功能

---

**注意**: 请确保在生产环境中使用前充分测试所有配置。
