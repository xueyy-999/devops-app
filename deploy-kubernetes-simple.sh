#!/bin/bash

# 简化的Kubernetes部署脚本
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

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    log_error "请使用root用户运行此脚本"
    exit 1
fi

log_info "开始部署Kubernetes集群..."

# 1. 更新系统
log_info "更新系统包..."
dnf update -y

# 2. 安装基础软件
log_info "安装基础软件..."
dnf install -y curl wget vim htop net-tools bind-utils telnet tcpdump lsof rsync git unzip jq yum-utils device-mapper-persistent-data lvm2

# 3. 配置时区
log_info "配置时区..."
timedatectl set-timezone Asia/Shanghai

# 4. 配置NTP
log_info "配置NTP..."
dnf install -y chrony
systemctl enable chronyd
systemctl start chronyd

# 5. 配置防火墙
log_info "配置防火墙..."
systemctl enable firewalld
systemctl start firewalld

# 6. 禁用SELinux
log_info "禁用SELinux..."
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# 7. 配置系统参数
log_info "配置系统参数..."
cat >> /etc/sysctl.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
EOF

sysctl -p

# 8. 加载内核模块
log_info "加载内核模块..."
modprobe br_netfilter
modprobe overlay
echo 'br_netfilter' > /etc/modules-load.d/k8s.conf
echo 'overlay' >> /etc/modules-load.d/k8s.conf

# 9. 禁用swap
log_info "禁用swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 10. 安装Docker
log_info "安装Docker..."
dnf install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

# 11. 配置Docker
log_info "配置Docker..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF

systemctl restart docker

# 12. 安装Kubernetes
log_info "安装Kubernetes..."
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

dnf install -y kubelet kubeadm kubectl
systemctl enable kubelet

# 13. 初始化Kubernetes集群
log_info "初始化Kubernetes集群..."
kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12

# 14. 配置kubectl
log_info "配置kubectl..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# 15. 安装网络插件
log_info "安装Flannel网络插件..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 16. 等待节点就绪
log_info "等待节点就绪..."
sleep 30
kubectl get nodes

# 17. 安装存储类
log_info "安装本地存储类..."
mkdir -p /mnt/local-storage
cat > /tmp/local-storage-class.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-$(hostname | tr '.' '-')
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/local-storage
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $(hostname)
EOF

kubectl apply -f /tmp/local-storage-class.yaml

# 18. 安装metrics-server
log_info "安装metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 19. 验证部署
log_info "验证部署..."
kubectl get nodes
kubectl get pods --all-namespaces

log_success "Kubernetes集群部署完成！"
log_info "访问信息："
log_info "  - 集群状态: kubectl get nodes"
log_info "  - Pod状态: kubectl get pods --all-namespaces"
log_info "  - 服务状态: kubectl get services --all-namespaces"
