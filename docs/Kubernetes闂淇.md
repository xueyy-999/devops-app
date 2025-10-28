# Kubernetes仓库问题修复指南

## 问题描述
在部署Kubernetes时遇到以下错误：
```
HTTP Error 403: Forbidden
url: https://pkgs.k8s.io/core:/stable:/v1/rpm/repodata/repomd.xml
```

## 问题原因
Kubernetes官方仓库的URL格式有问题，导致访问被拒绝。

## 解决方案

### 方案1：使用修复脚本（推荐）
```bash
# 1. 运行修复脚本
chmod +x fix-kubernetes-repo.sh
./fix-kubernetes-repo.sh

# 2. 重新运行Kubernetes安装
ansible-playbook -i inventory/hosts.yml playbooks/03-kubernetes-fixed.yml
```

### 方案2：手动修复
```bash
# 1. 删除有问题的仓库文件
rm -f /etc/yum.repos.d/kubernetes.repo

# 2. 创建新的仓库配置
cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 3. 清理缓存
dnf clean all
dnf makecache

# 4. 重新运行安装
ansible-playbook -i inventory/hosts.yml playbooks/03-kubernetes-fixed.yml
```

### 方案3：使用简化脚本
```bash
# 直接使用简化脚本部署
chmod +x deploy-kubernetes-simple.sh
./deploy-kubernetes-simple.sh
```

## 验证步骤

### 1. 检查仓库状态
```bash
dnf repolist | grep kubernetes
```

### 2. 检查Kubernetes组件
```bash
kubelet --version
kubeadm version
kubectl version --client
```

### 3. 检查集群状态
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## 常见问题

### Q1: 仍然无法访问仓库
**解决方案：**
```bash
# 使用其他镜像源
cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/doc/yum-key.gpg https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

### Q2: 网络连接问题
**解决方案：**
```bash
# 检查网络连接
ping -c 3 mirrors.aliyun.com
ping -c 3 mirrors.tuna.tsinghua.edu.cn

# 如果网络有问题，使用本地安装包
dnf install -y kubelet kubeadm kubectl --downloadonly --downloaddir=/tmp/k8s-packages
```

### Q3: 版本兼容性问题
**解决方案：**
```bash
# 检查CentOS版本
cat /etc/redhat-release

# 根据版本选择对应的仓库
# CentOS 7: kubernetes-el7-x86_64
# CentOS 8: kubernetes-el8-x86_64
# CentOS 9: kubernetes-el9-x86_64
```

## 完整部署流程

### 1. 基础环境准备
```bash
# 运行基础环境配置
ansible-playbook -i inventory/hosts.yml playbooks/01-common-setup.yml
```

### 2. Docker安装
```bash
# 运行Docker安装
ansible-playbook -i inventory/hosts.yml playbooks/02-docker-setup.yml
```

### 3. Kubernetes安装
```bash
# 修复仓库问题
./fix-kubernetes-repo.sh

# 运行Kubernetes安装
ansible-playbook -i inventory/hosts.yml playbooks/03-kubernetes-fixed.yml
```

### 4. 验证部署
```bash
# 运行验证脚本
./scripts/verify-deployment.sh
```

## 论文展示要点

### 1. 问题分析
- 展示错误信息
- 分析问题原因
- 说明解决方案

### 2. 技术实现
- 展示修复脚本
- 展示配置变更
- 展示验证结果

### 3. 创新点
- 自动化问题诊断
- 多镜像源支持
- 容错机制设计

### 4. 测试验证
- 功能测试
- 性能测试
- 可用性测试

## 总结

通过使用阿里云镜像源替代官方仓库，成功解决了Kubernetes安装过程中的仓库访问问题。这种方法不仅提高了安装成功率，还加快了下载速度，为后续的云原生DevOps平台部署奠定了坚实基础。
