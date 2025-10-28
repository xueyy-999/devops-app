# 配置说明

本文档详细说明项目中的各种配置项。

## Ansible 配置

### ansible.cfg

Ansible 全局配置文件，位于项目根目录。

```ini
[defaults]
# 默认 inventory 文件位置
inventory = inventory/hosts.yml

# 禁用 SSH 主机密钥检查
host_key_checking = False

# SSH 连接超时时间（秒）
timeout = 30

# 并发执行的进程数
forks = 10

# Facts 收集策略
gathering = smart

# Facts 缓存方式
fact_caching = memory

# 输出格式
stdout_callback = yaml

# 启用 Ansible 回调插件
bin_ansible_callbacks = True

[ssh_connection]
# SSH 连接参数
ssh_args = -o ControlMaster=auto -o ControlPersist=60s

# 启用 SSH 管道化，提高性能
pipelining = True

# SSH 控制路径
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[privilege_escalation]
# 启用权限提升
become = True

# 权限提升方式
become_method = sudo

# 提升到的用户
become_user = root

# 不询问密码
become_ask_pass = False
```

### 配置项说明

| 配置项 | 说明 | 默认值 | 推荐值 |
|--------|------|--------|--------|
| `inventory` | Inventory 文件路径 | - | `inventory/hosts.yml` |
| `host_key_checking` | SSH 主机密钥检查 | True | False（测试环境） |
| `timeout` | 连接超时时间 | 10 | 30 |
| `forks` | 并发执行数 | 5 | 10-20 |
| `gathering` | Facts 收集策略 | implicit | smart |
| `pipelining` | SSH 管道化 | False | True |

## Inventory 配置

### 多节点配置 (inventory/hosts.yml)

```yaml
all:
  vars:
    # 全局变量
    ansible_user: root
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    
    # 系统配置
    timezone: "Asia/Shanghai"
    ntp_servers:
      - "ntp.aliyun.com"
      - "time.windows.com"
    
    # 网络配置
    cluster_network: "192.168.1.0/24"
    service_network: "10.96.0.0/12"
    pod_network: "10.244.0.0/16"
    
  children:
    # Kubernetes 控制节点
    control_nodes:
      hosts:
        master-01:
          ansible_host: 192.168.1.10
          node_ip: 192.168.1.10
        master-02:
          ansible_host: 192.168.1.11
          node_ip: 192.168.1.11
      vars:
        node_role: master
    
    # Kubernetes 工作节点
    compute_nodes:
      hosts:
        worker-01:
          ansible_host: 192.168.1.20
          node_ip: 192.168.1.20
        worker-02:
          ansible_host: 192.168.1.21
          node_ip: 192.168.1.21
        worker-03:
          ansible_host: 192.168.1.22
          node_ip: 192.168.1.22
      vars:
        node_role: worker
    
    # 存储节点（可选）
    storage_nodes:
      hosts:
        storage-01:
          ansible_host: 192.168.1.30
          node_ip: 192.168.1.30
    
    # 监控节点
    monitoring_nodes:
      hosts:
        monitor-01:
          ansible_host: 192.168.1.40
          node_ip: 192.168.1.40
    
    # CI/CD 节点
    cicd_nodes:
      hosts:
        cicd-01:
          ansible_host: 192.168.1.50
          node_ip: 192.168.1.50
```

### 单节点配置 (inventory/single-node.yml)

```yaml
all:
  vars:
    ansible_connection: local
    
    # 系统配置
    timezone: "Asia/Shanghai"
    ntp_servers:
      - "ntp.aliyun.com"
    
    # 网络配置
    cluster_network: "192.168.76.0/24"
    service_network: "10.96.0.0/12"
    pod_network: "10.244.0.0/16"
    
  hosts:
    localhost:
      ansible_host: 127.0.0.1
      node_ip: 192.168.76.141
```

### Inventory 变量说明

#### 全局变量

| 变量 | 说明 | 示例 | 必需 |
|------|------|------|------|
| `ansible_user` | SSH 用户 | `root` | 是 |
| `ansible_host` | 目标主机 IP | `192.168.1.10` | 是 |
| `ansible_ssh_private_key_file` | SSH 私钥路径 | `~/.ssh/id_rsa` | 否 |
| `node_ip` | 节点 IP 地址 | `192.168.1.10` | 是 |
| `node_role` | 节点角色 | `master`/`worker` | 是 |

#### 系统配置变量

| 变量 | 说明 | 默认值 | 可选值 |
|------|------|--------|--------|
| `timezone` | 时区 | `Asia/Shanghai` | 任意有效时区 |
| `ntp_servers` | NTP 服务器列表 | `["ntp.aliyun.com"]` | 任意 NTP 服务器 |
| `selinux_state` | SELinux 状态 | `disabled` | `enforcing`/`permissive`/`disabled` |

#### 网络配置变量

| 变量 | 说明 | 默认值 | 说明 |
|------|------|--------|------|
| `cluster_network` | 集群网络 | `192.168.1.0/24` | 节点所在网络 |
| `service_network` | Service 网络 | `10.96.0.0/12` | K8s Service CIDR |
| `pod_network` | Pod 网络 | `10.244.0.0/16` | K8s Pod CIDR |
| `dns_servers` | DNS 服务器 | `["8.8.8.8"]` | DNS 服务器列表 |

## 部署配置

### site.yml

主部署 Playbook 配置。

```yaml
---
- name: 部署云原生DevOps平台
  hosts: all
  become: yes
  gather_facts: yes
  vars:
    # 部署模式: full, minimal, custom
    deployment_mode: "full"
    
    # 跳过验证
    skip_verification: false
    
    # 系统配置
    timezone: "Asia/Shanghai"
    ntp_servers:
      - "ntp.aliyun.com"
      - "time.windows.com"
    
    # 网络配置
    cluster_network: "192.168.1.0/24"
    service_network: "10.96.0.0/12"
    pod_network: "10.244.0.0/16"
    
    # 应用配置
    app_namespace: "production"
    app_name: "web-app"
    app_replicas: 3
    app_domain: "app.example.com"
    
    # 监控配置
    prometheus_port: 9090
    grafana_port: 3000
    alertmanager_port: 9093
    
    # CI/CD 配置
    gitlab_port: 80
    jenkins_port: 8080
    harbor_port: 80
```

### 部署模式

#### full - 完整部署

部署所有组件：
- 基础环境配置
- Docker 安装
- Kubernetes 集群
- 监控系统（Prometheus + Grafana）
- CI/CD 系统（GitLab + Jenkins + Harbor）
- 示例应用

```bash
./deploy.sh --mode full
```

#### minimal - 最小化部署

只部署核心组件：
- 基础环境配置
- Docker 安装
- Kubernetes 集群

```bash
./deploy.sh --mode minimal
```

#### custom - 自定义部署

通过标签选择部署组件：

```bash
# 只部署基础环境和 Docker
./deploy.sh --mode custom --tags setup,common,docker

# 部署 Kubernetes 和监控
./deploy.sh --mode custom --tags kubernetes,monitoring
```

可用标签：
- `setup`: 基础环境配置
- `common`: 系统配置
- `docker`: Docker 安装
- `kubernetes`: Kubernetes 集群
- `monitoring`: 监控系统
- `cicd`: CI/CD 系统
- `application`: 应用部署
- `verify`: 系统验证

## Kubernetes 配置

### kubeadm 配置

Kubernetes 集群初始化配置（模板：`templates/kubeadm-config.yaml.j2`）

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "{{ control_plane_endpoint }}:6443"
networking:
  serviceSubnet: "{{ service_network }}"
  podSubnet: "{{ pod_network }}"
  dnsDomain: "cluster.local"
apiServer:
  certSANs:
    - "{{ ansible_host }}"
    - "{{ node_ip }}"
  extraArgs:
    authorization-mode: "Node,RBAC"
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
etcd:
  local:
    dataDir: "/var/lib/etcd"
```

### kubelet 配置

kubelet 运行时配置（模板：`templates/kubelet-config.yaml.j2`）

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
clusterDNS:
  - "{{ cluster_dns }}"
clusterDomain: "cluster.local"
```

## Docker 配置

Docker daemon 配置（模板：`templates/daemon.json.j2`）

```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "insecure-registries": [
    "{{ harbor_host }}:{{ harbor_port }}"
  ]
}
```

### 配置说明

| 配置项 | 说明 | 推荐值 |
|--------|------|--------|
| `exec-opts` | cgroup 驱动 | `systemd` |
| `log-driver` | 日志驱动 | `json-file` |
| `max-size` | 单个日志文件大小 | `100m` |
| `max-file` | 保留日志文件数 | `3` |
| `storage-driver` | 存储驱动 | `overlay2` |
| `registry-mirrors` | 镜像加速器 | 国内镜像源 |

## 监控配置

### Prometheus 配置

基本配置（模板：`templates/prometheus.yml.j2`）

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - "{{ alertmanager_host }}:{{ alertmanager_port }}"

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
    - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
    - role: node

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
```

### Grafana 配置

配置文件（模板：`templates/grafana.ini.j2`）

```ini
[server]
protocol = http
http_port = {{ grafana_port }}
domain = {{ grafana_domain }}

[database]
type = sqlite3
path = grafana.db

[security]
admin_user = admin
admin_password = {{ grafana_admin_password }}

[auth.anonymous]
enabled = false

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/kubernetes-cluster.json
```

## 应用配置

### Deployment 配置

示例（模板：`templates/app-deployment.yaml.j2`）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ app_name }}
  namespace: {{ app_namespace }}
spec:
  replicas: {{ app_replicas }}
  selector:
    matchLabels:
      app: {{ app_name }}
  template:
    metadata:
      labels:
        app: {{ app_name }}
    spec:
      containers:
      - name: {{ app_name }}
        image: {{ app_image }}:{{ app_version }}
        ports:
        - containerPort: {{ app_port }}
        resources:
          requests:
            memory: "{{ app_memory_request }}"
            cpu: "{{ app_cpu_request }}"
          limits:
            memory: "{{ app_memory_limit }}"
            cpu: "{{ app_cpu_limit }}"
        env:
        - name: APP_ENV
          value: "{{ app_environment }}"
```

### HPA 配置

自动扩缩容（模板：`templates/app-hpa.yaml.j2`）

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ app_name }}-hpa
  namespace: {{ app_namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ app_name }}
  minReplicas: {{ hpa_min_replicas }}
  maxReplicas: {{ hpa_max_replicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ hpa_cpu_threshold }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ hpa_memory_threshold }}
```

## 环境变量

### 部署脚本环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `ANSIBLE_CONFIG` | Ansible 配置文件路径 | `./ansible.cfg` |
| `ANSIBLE_INVENTORY` | Inventory 文件路径 | `inventory/hosts.yml` |
| `ANSIBLE_LOG_PATH` | Ansible 日志路径 | `/var/log/ansible.log` |

### Kubernetes 环境变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `KUBECONFIG` | kubectl 配置文件 | `~/.kube/config` |
| `K8S_VERSION` | Kubernetes 版本 | `1.28.0` |
| `KUBE_APISERVER` | API Server 地址 | `https://192.168.1.10:6443` |

## 端口配置

### 默认端口

| 服务 | 端口 | 说明 |
|------|------|------|
| Kubernetes API | 6443 | API Server |
| etcd | 2379-2380 | etcd 集群 |
| kubelet | 10250 | kubelet API |
| kube-scheduler | 10259 | Scheduler |
| kube-controller | 10257 | Controller Manager |
| NodePort | 30000-32767 | NodePort 范围 |
| Prometheus | 9090 | Prometheus Web UI |
| Grafana | 3000 | Grafana Web UI |
| Alertmanager | 9093 | Alertmanager Web UI |
| GitLab | 80/443 | GitLab Web UI |
| Jenkins | 8080 | Jenkins Web UI |
| Harbor | 80/443 | Harbor Web UI |

### 防火墙规则

需要开放的端口：

```bash
# Kubernetes Master
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250-10252/tcp
firewall-cmd --permanent --add-port=10257/tcp
firewall-cmd --permanent --add-port=10259/tcp

# Kubernetes Worker
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp

# Flannel
firewall-cmd --permanent --add-port=8472/udp

# 重载防火墙
firewall-cmd --reload
```

## 配置最佳实践

1. **安全性**
   - 使用强密码
   - 限制 SSH 访问
   - 启用防火墙
   - 定期更新证书

2. **性能**
   - 根据负载调整资源限制
   - 配置适当的副本数
   - 使用缓存和持久连接
   - 优化网络配置

3. **可维护性**
   - 使用变量而非硬编码
   - 添加详细注释
   - 使用版本控制
   - 记录配置变更

4. **可靠性**
   - 配置备份策略
   - 实施健康检查
   - 设置告警规则
   - 测试故障恢复

## 故障排除

### 常见配置问题

1. **SSH 连接失败**
   - 检查 `ansible_host` 和 `ansible_user` 配置
   - 验证 SSH 密钥权限（600）
   - 确认防火墙允许 SSH 连接

2. **Kubernetes 集群初始化失败**
   - 检查网络配置（CIDR 不能重叠）
   - 确认 swap 已禁用
   - 验证容器运行时配置

3. **应用部署失败**
   - 检查镜像地址是否正确
   - 验证命名空间存在
   - 确认资源配额足够

## 相关文档

- [快速开始](quick-start.md)
- [部署指南](deployment-guide.md)
- [项目结构](PROJECT_STRUCTURE.md)
- [故障排除](kubernetes-fix-guide.md)

