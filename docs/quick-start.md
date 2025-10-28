# 快速开始指南

## 一键部署命令

### 完整部署
```bash
# 克隆项目
git clone <repository-url>
cd cloud-native-devops-platform

# 配置服务器清单
vim inventory/hosts.yml

# 执行完整部署
./deploy.sh --mode full
```

### 最小化部署
```bash
# 只部署核心组件
./deploy.sh --mode minimal
```

### 自定义部署
```bash
# 只部署基础环境
./deploy.sh --mode custom --tags setup,common

# 只部署Docker和Kubernetes
./deploy.sh --mode custom --tags setup,common,docker,kubernetes
```

## 验证部署

### 检查服务状态
```bash
# 检查Docker服务
systemctl status docker

# 检查Kubernetes集群
kubectl get nodes
kubectl get pods --all-namespaces

# 检查监控服务
systemctl status prometheus
systemctl status grafana-server

# 检查CI/CD服务
systemctl status gitlab
systemctl status jenkins
```

### 访问服务
- **应用地址**: http://app.example.com
- **监控地址**: http://<ip>:9090
- **仪表板**: http://<ip>:3000
- **GitLab**: http://<ip>:80
- **Jenkins**: http://<ip>:8080
- **Harbor**: http://<ip>:80

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
```

### 应用管理
```bash
# 查看应用Pod
kubectl get pods -n production -l app=web-app

# 查看应用日志
kubectl logs -n production -l app=web-app -f

# 扩缩容应用
kubectl scale deployment web-app --replicas=5 -n production
```

## 故障排除

### 常见问题
1. **Docker服务启动失败**: 检查Docker配置和日志
2. **Kubernetes节点NotReady**: 检查网络和CNI插件
3. **Pod启动失败**: 检查资源限制和镜像
4. **网络连接问题**: 检查防火墙和DNS配置

### 日志位置
- **系统日志**: `/var/log/messages`
- **Docker日志**: `journalctl -u docker`
- **Kubernetes日志**: `journalctl -u kubelet`
- **应用日志**: `kubectl logs <pod-name>`

## 下一步操作

1. **配置域名解析**: 添加DNS记录
2. **配置SSL证书**: 使用Let's Encrypt
3. **设置监控告警**: 配置告警规则
4. **配置CI/CD流水线**: 设置自动化部署
5. **备份重要数据**: 定期备份配置和数据

## 获取帮助

- **文档**: 查看README.md和DEPLOYMENT.md
- **问题反馈**: 提交GitHub Issue
- **社区支持**: 加入讨论群组
