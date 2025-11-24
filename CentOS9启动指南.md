# 🚀 CentOS 9 虚拟机启动指南

## 📋 概述

这个指南帮助你在 VMware CentOS 9 虚拟机上启动五个核心 DevOps 服务：
- **GitLab** 🔷 (端口 80)
- **Jenkins** ⚙️ (端口 8080)
- **Harbor** 🐳 (端口 5000)
- **Prometheus** 📊 (端口 9090)
- **Grafana** 📈 (端口 3000)

## 🎯 快速开始 (3步)

### 第1步: 检查服务状态
```bash
# 查看当前服务状态
sudo bash 检查服务状态.sh
```

这个脚本会显示：
- ✅ 各个服务是否运行
- 🔌 各个端口是否开放
- 🌐 各个服务是否可访问
- 💻 系统资源使用情况

### 第2步: 启动所有服务
```bash
# 启动所有服务
sudo bash 启动所有服务.sh
```

这个脚本会：
- 启动 Docker 和 Containerd
- 启动五个核心服务
- 显示服务状态
- 显示访问信息

### 第3步: 访问服务
根据脚本输出的IP地址，在浏览器中访问各个服务：
- GitLab: http://192.168.76.141
- Jenkins: http://192.168.76.141:8080
- Harbor: http://192.168.76.141:5000
- Prometheus: http://192.168.76.141:9090
- Grafana: http://192.168.76.141:3000

## 📁 脚本说明

### 1. 启动所有服务.sh
**功能**: 启动所有 DevOps 平台服务

**使用方法**:
```bash
sudo bash 启动所有服务.sh
```

**做什么**:
- ✅ 启动 Docker 和 Containerd
- ✅ 启动 GitLab、Jenkins、Harbor
- ✅ 启动 Prometheus 和 Grafana
- ✅ 检查服务状态
- ✅ 显示访问信息

### 2. 检查服务状态.sh
**功能**: 检查所有服务的运行状态

**使用方法**:
```bash
sudo bash 检查服务状态.sh
```

**显示内容**:
- 📋 各个服务的运行状态
- 🔌 各个端口是否开放
- 🌐 各个服务是否可访问
- 💻 系统资源使用情况

### 3. 启动五个服务.sh
**功能**: 只启动五个核心服务（不启动基础服务）

**使用方法**:
```bash
sudo bash 启动五个服务.sh
```

## 🔧 常用命令

### 启动单个服务
```bash
# 启动 GitLab
sudo systemctl start gitlab

# 启动 Jenkins
sudo systemctl start jenkins

# 启动 Harbor
sudo systemctl start harbor

# 启动 Prometheus
sudo systemctl start prometheus

# 启动 Grafana
sudo systemctl start grafana-server
```

### 停止单个服务
```bash
sudo systemctl stop <service-name>
```

### 重启单个服务
```bash
sudo systemctl restart <service-name>
```

### 查看服务状态
```bash
sudo systemctl status <service-name>
```

### 查看服务日志
```bash
# 实时查看日志
sudo journalctl -u <service-name> -f

# 查看最后100行日志
sudo journalctl -u <service-name> -n 100

# 查看特定时间的日志
sudo journalctl -u <service-name> --since "2025-11-04 10:00:00"
```

### 检查端口
```bash
# 检查所有监听的端口
sudo netstat -tuln

# 检查特定端口
sudo netstat -tuln | grep :80
sudo netstat -tuln | grep :8080
sudo netstat -tuln | grep :5000
sudo netstat -tuln | grep :9090
sudo netctl -tuln | grep :3000
```

## 🔐 默认账号密码

| 服务 | 账号 | 密码 |
|------|------|------|
| **GitLab** | root | /etc/gitlab/initial_root_password |
| **Jenkins** | admin | 查看部署日志 |
| **Harbor** | admin | Harbor12345 |
| **Prometheus** | - | 无需认证 |
| **Grafana** | admin | admin123 |

## 🐛 故障排除

### 问题1: 服务启动失败
**症状**: 运行脚本后，某个服务显示 ❌ 未运行

**解决方案**:
```bash
# 1. 查看服务日志
sudo journalctl -u <service-name> -f

# 2. 检查服务是否存在
sudo systemctl list-unit-files | grep <service-name>

# 3. 手动启动服务
sudo systemctl start <service-name>

# 4. 查看启动错误
sudo systemctl status <service-name>
```

### 问题2: 无法访问服务
**症状**: 浏览器无法打开服务网页

**解决方案**:
```bash
# 1. 检查端口是否开放
sudo netstat -tuln | grep :<port>

# 2. 检查防火墙
sudo firewall-cmd --list-all

# 3. 开放端口
sudo firewall-cmd --permanent --add-port=<port>/tcp
sudo firewall-cmd --reload

# 4. 测试连接
curl http://localhost:<port>
```

### 问题3: 内存或磁盘不足
**症状**: 服务启动后立即停止，或启动缓慢

**解决方案**:
```bash
# 1. 检查磁盘空间
df -h

# 2. 检查内存使用
free -h

# 3. 清理日志
sudo journalctl --vacuum=100M

# 4. 清理Docker
sudo docker system prune -a
```

### 问题4: 服务相互依赖问题
**症状**: 某个服务启动失败，提示依赖问题

**解决方案**:
```bash
# 1. 按顺序启动服务
sudo systemctl start docker
sleep 5
sudo systemctl start gitlab
sleep 10
sudo systemctl start jenkins
sleep 10
sudo systemctl start harbor
sleep 10
sudo systemctl start prometheus
sleep 10
sudo systemctl start grafana-server

# 2. 检查服务依赖
sudo systemctl list-dependencies <service-name>
```

## 📊 监控和维护

### 实时监控
```bash
# 监控系统资源
top

# 监控网络流量
iftop

# 监控磁盘I/O
iostat -x 1
```

### 定期检查
```bash
# 每天检查一次服务状态
sudo bash 检查服务状态.sh

# 查看系统日志
sudo journalctl -p err -f
```

### 备份重要数据
```bash
# 备份GitLab数据
sudo gitlab-backup create

# 备份Grafana数据
sudo tar -czf grafana-backup.tar.gz /var/lib/grafana/

# 备份Prometheus数据
sudo tar -czf prometheus-backup.tar.gz /var/lib/prometheus/
```

## 📞 获取帮助

### 查看脚本帮助
```bash
# 查看脚本内容
cat 启动所有服务.sh
cat 检查服务状态.sh

# 查看脚本注释
grep "^#" 启动所有服务.sh
```

### 查看系统日志
```bash
# 查看所有系统日志
sudo journalctl -f

# 查看特定服务的日志
sudo journalctl -u <service-name> -f
```

### 查看配置文件
```bash
# GitLab配置
sudo cat /etc/gitlab/gitlab.rb

# Jenkins配置
sudo cat /var/lib/jenkins/config.xml

# Prometheus配置
sudo cat /etc/prometheus/prometheus.yml

# Grafana配置
sudo cat /etc/grafana/grafana.ini
```

## ✨ 最佳实践

1. **定期检查服务状态**
   ```bash
   sudo bash 检查服务状态.sh
   ```

2. **定期查看日志**
   ```bash
   sudo journalctl -u gitlab -f
   ```

3. **定期备份数据**
   ```bash
   sudo gitlab-backup create
   ```

4. **定期更新系统**
   ```bash
   sudo dnf update -y
   ```

5. **监控系统资源**
   ```bash
   top
   df -h
   free -h
   ```

## 📝 常见问题

**Q: 如何修改服务器IP地址?**
A: 编辑 `/etc/sysconfig/network-scripts/ifcfg-*` 文件，然后重启网络服务

**Q: 如何修改服务端口?**
A: 编辑各个服务的配置文件，然后重启服务

**Q: 如何卸载服务?**
A: 使用 `sudo dnf remove <package-name>` 命令

**Q: 如何重新部署?**
A: 运行 `./deploy.sh --mode full` 脚本

---

**最后更新**: 2025-11-04
**版本**: 1.0.0
**适用系统**: CentOS 9 / Rocky Linux 9

