# Nginx 启动失败修复指南

## 🔍 问题原因

Nginx 启动失败的原因是**端口冲突**：

1. **nginx** 监听 **80** 端口
2. **GitLab** 也配置为 **80** 端口
3. **Harbor** 也配置为 **80** 端口

三个服务同时想用 80 端口，导致冲突！

## ✅ 已修复的文件

### 1. `playbooks/05-cicd-setup.yml` - 修改端口配置

**修改前：**
```yaml
vars:
  gitlab_port: 80      # ❌ 与 nginx 冲突
  jenkins_port: 8080
  harbor_port: 80      # ❌ 与 nginx 冲突
```

**修改后：**
```yaml
vars:
  gitlab_port: 8081    # ✅ 修改为 8081
  jenkins_port: 8080   # ✅ 保持不变
  harbor_port: 5000    # ✅ 修改为 5000
```

### 2. `templates/nginx.conf.j2` - 更新反向代理配置

**修改后：**
```nginx
upstream harbor {
    server 127.0.0.1:5000;  # ✅ 匹配新的 harbor 端口
}
```

### 3. `playbooks/05-cicd-setup.yml` - 添加 nginx 准备任务

新增以下任务（在启动 nginx 前）：
- ✅ 创建 nginx 日志目录
- ✅ 检查并创建 nginx 用户
- ✅ 测试 nginx 配置语法
- ✅ 配置文件验证

## 🚀 在虚拟机上应用修复

### 方法 1：使用自动修复脚本（最简单）⭐

```bash
cd /root/cloud-native-devops-platform

# 1. 传输修复脚本（从 Windows）
# scp fix-nginx-issue.sh root@虚拟机IP:/root/cloud-native-devops-platform/

# 2. 运行修复脚本
chmod +x fix-nginx-issue.sh
bash fix-nginx-issue.sh
```

这个脚本会：
- ✅ 检查并安装 nginx
- ✅ 创建 nginx 用户和目录
- ✅ 检查端口占用
- ✅ 测试配置
- ✅ 启动 nginx

### 方法 2：手动修复 nginx 问题

```bash
# 1. 停止 nginx
systemctl stop nginx

# 2. 检查 80 端口占用
netstat -tuln | grep :80
# 或
ss -tuln | grep :80

# 3. 如果有其他服务占用，停止它
systemctl stop httpd    # Apache
systemctl stop gitlab   # GitLab

# 4. 创建 nginx 用户（如果不存在）
useradd -r -M -s /sbin/nologin nginx

# 5. 创建日志目录
mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx

# 6. 测试 nginx 配置
nginx -t

# 7. 启动 nginx
systemctl start nginx
systemctl enable nginx

# 8. 检查状态
systemctl status nginx
```

### 方法 3：更新 playbook 文件并重新运行

```bash
cd /root/cloud-native-devops-platform

# 1. 备份原文件
cp playbooks/05-cicd-setup.yml playbooks/05-cicd-setup.yml.backup
cp templates/nginx.conf.j2 templates/nginx.conf.j2.backup

# 2. 修改 playbooks/05-cicd-setup.yml 中的端口配置
vim playbooks/05-cicd-setup.yml

# 找到并修改:
# gitlab_port: 8081      # 从 80 改为 8081
# harbor_port: 5000      # 从 80 改为 5000

# 3. 重新运行 CI/CD 部署
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml
```

## 📊 修复后的服务端口分配

| 服务 | 端口 | 访问地址 | 说明 |
|------|------|---------|------|
| **Nginx** | 80 | `http://IP` | 反向代理入口 |
| **GitLab** | 8081 | `http://IP:8081` 或通过 Nginx `/` | 代码仓库 |
| **Jenkins** | 8080 | `http://IP:8080` 或通过 Nginx `/jenkins/` | CI/CD 服务器 |
| **Harbor** | 5000 | `http://IP:5000` 或通过 Nginx `/harbor/` | 镜像仓库 |

## 🔍 故障排查

### 1. 查看 nginx 错误日志

```bash
# 查看 nginx 服务日志
journalctl -u nginx -n 100

# 查看 nginx 错误日志
tail -f /var/log/nginx/error.log

# 查看 nginx 访问日志
tail -f /var/log/nginx/access.log
```

### 2. 测试 nginx 配置

```bash
# 测试配置语法
nginx -t

# 查看当前配置
nginx -T

# 重新加载配置（不中断服务）
nginx -s reload
```

### 3. 检查端口占用

```bash
# 查看所有监听端口
netstat -tuln
# 或
ss -tuln

# 查看谁在使用 80 端口
netstat -tulnp | grep :80
# 或
ss -tulnp | grep :80

# 查看进程
ps aux | grep nginx
```

### 4. 检查防火墙

```bash
# 查看防火墙状态
firewall-cmd --state

# 查看开放的端口
firewall-cmd --list-all

# 如果 80 端口未开放，添加规则
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
```

### 5. 检查 SELinux

```bash
# 查看 SELinux 状态
getenforce

# 如果是 Enforcing，允许 nginx 网络连接
setsebool -P httpd_can_network_connect 1

# 查看 SELinux 拒绝日志
ausearch -m avc -ts recent | grep nginx
```

## 🎯 验证修复

```bash
# 1. 检查 nginx 状态
systemctl status nginx

# 2. 检查 nginx 进程
ps aux | grep nginx

# 3. 测试 nginx 响应
curl -I http://localhost

# 4. 检查监听端口
netstat -tuln | grep nginx

# 5. 访问测试
curl http://localhost
curl http://$(hostname -I | awk '{print $1}')
```

## 📝 完整的修复文件列表

需要在虚拟机上更新的文件：

1. **playbooks/05-cicd-setup.yml** - 修改端口配置和添加 nginx 准备任务
2. **templates/nginx.conf.j2** - 更新 harbor 端口配置

可选辅助文件：
3. **fix-nginx-issue.sh** - 自动诊断和修复脚本

## 🔄 重新运行部署

如果你已经更新了 playbook 文件，可以重新运行：

```bash
cd /root/cloud-native-devops-platform

# 只运行 CI/CD 部署（步骤 5）
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml

# 或者跳过已完成的步骤，只配置 nginx
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml --start-at-task="创建nginx日志目录"
```

## ⚠️ 注意事项

1. **端口冲突**: 确保没有其他服务占用 80 端口
2. **防火墙**: 确保 80 端口在防火墙中开放
3. **SELinux**: 如果启用，需要配置 SELinux 策略
4. **用户权限**: nginx 需要 nginx 用户存在
5. **日志目录**: 确保 `/var/log/nginx` 目录存在且有正确权限

## 💡 常见问题

### Q1: nginx 配置测试失败？

```bash
# 查看详细错误
nginx -t

# 检查配置文件语法
cat /etc/nginx/nginx.conf
```

### Q2: nginx 启动后立即停止？

```bash
# 查看详细日志
journalctl -xeu nginx.service

# 检查错误日志
tail -100 /var/log/nginx/error.log
```

### Q3: 无法访问 nginx？

```bash
# 检查防火墙
firewall-cmd --list-all

# 添加端口
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload

# 检查监听
netstat -tuln | grep :80
```

## 📞 获取帮助

如果问题仍未解决：

1. 运行诊断脚本: `bash fix-nginx-issue.sh`
2. 查看日志: `journalctl -u nginx -n 100`
3. 检查配置: `nginx -t`
4. 查看端口: `netstat -tuln`

---

修复后，nginx 应该能正常启动并提供反向代理服务！

