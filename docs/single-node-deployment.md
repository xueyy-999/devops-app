# 单节点云原生DevOps平台部署

基于你的网络配置（IP: 192.168.76.141），这是一个简化的单节点部署方案。

## 快速开始

### 1. 部署命令
```bash
# 使用单节点部署脚本
./deploy-single.sh

# 或者使用ansible-playbook
ansible-playbook -i inventory/single-node.yml playbooks/single-node-deploy.yml
```

### 2. 验证部署
```bash
# 快速验证
./scripts/quick-verify.sh

# 或者手动检查
kubectl get nodes
kubectl get pods --all-namespaces
systemctl status docker
systemctl status kubelet
```

### 3. 访问服务
- **应用地址**: http://192.168.76.141
- **监控地址**: http://192.168.76.141:9090
- **仪表板**: http://192.168.76.141:3000
- **GitLab**: http://192.168.76.141
- **Jenkins**: http://192.168.76.141:8080
- **Harbor**: http://192.168.76.141

## 部署步骤

### 1. 基础环境配置
```bash
# 检查系统
cat /etc/os-release
uname -r
free -h
df -h

# 检查网络
ip a
ping -c 3 8.8.8.8
```

### 2. 执行部署
```bash
# 完整部署
./deploy-single.sh

# 分步部署
./deploy-single.sh --tags setup,common
./deploy-single.sh --tags setup,docker
./deploy-single.sh --tags setup,kubernetes
./deploy-single.sh --tags setup,monitoring
./deploy-single.sh --tags setup,cicd
./deploy-single.sh --tags deploy,application
```

### 3. 验证部署
```bash
# 检查服务状态
systemctl status docker
systemctl status kubelet
systemctl status prometheus
systemctl status grafana-server

# 检查Kubernetes
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# 检查应用
kubectl get pods -n production -l app=web-app
kubectl get services -n production -l app=web-app
kubectl get ingress -n production -l app=web-app
```

## 常用命令

### 系统管理
```bash
# 查看服务状态
systemctl status <service-name>

# 重启服务
systemctl restart <service-name>

# 查看日志
journalctl -u <service-name> -f
```

### Kubernetes管理
```bash
# 查看节点
kubectl get nodes -o wide

# 查看Pod
kubectl get pods --all-namespaces

# 查看服务
kubectl get services --all-namespaces

# 查看Ingress
kubectl get ingress --all-namespaces

# 查看应用
kubectl get pods -n production -l app=web-app
kubectl get services -n production -l app=web-app
kubectl get ingress -n production -l app=web-app
```

### 应用管理
```bash
# 查看应用日志
kubectl logs -n production -l app=web-app -f

# 扩缩容应用
kubectl scale deployment web-app --replicas=3 -n production

# 更新应用
kubectl set image deployment/web-app web-app=nginx:latest -n production

# 回滚应用
kubectl rollout undo deployment/web-app -n production
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
ping -c 3 8.8.8.8
telnet localhost 80
telnet localhost 9090
telnet localhost 3000
```

### 日志位置

- **系统日志**: `/var/log/messages`
- **Docker日志**: `journalctl -u docker`
- **Kubernetes日志**: `journalctl -u kubelet`
- **应用日志**: `kubectl logs <pod-name> -n <namespace>`

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

### 资源监控
```bash
# 查看系统资源
top
htop
free -h
df -h

# 查看Kubernetes资源
kubectl top nodes
kubectl top pods --all-namespaces
```

## 备份与恢复

### 备份数据
```bash
# 备份Kubernetes配置
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# 备份应用数据
kubectl get configmaps --all-namespaces -o yaml > configmaps-backup.yaml
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml
```

### 恢复数据
```bash
# 恢复Kubernetes配置
kubectl apply -f k8s-backup.yaml

# 恢复应用数据
kubectl apply -f configmaps-backup.yaml
kubectl apply -f secrets-backup.yaml
```

## 扩展功能

### 添加新应用
```bash
# 创建新应用
kubectl create deployment new-app --image=nginx:latest -n production

# 暴露服务
kubectl expose deployment new-app --port=80 --type=NodePort -n production

# 创建Ingress
kubectl create ingress new-app --rule="new-app.example.com/*=new-app:80" -n production
```

### 配置存储
```bash
# 创建存储类
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

## 联系信息

如有问题，请检查：
1. 服务状态和日志
2. 网络连接
3. 资源使用情况
4. 配置文件

---

**注意**: 这是一个单节点部署方案，适用于测试和学习环境。生产环境建议使用多节点部署。
