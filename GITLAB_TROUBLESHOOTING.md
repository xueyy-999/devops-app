# GitLab 500 错误排查指南

## 🔍 问题概述

你遇到的错误信息：
```
GitLab 检查失败（root=500, internal=500, primary=401, alt=500)
```

这表明：
- ✗ `root=500`: 根路径返回服务器内部错误
- ✗ `internal=500`: 内部接口返回服务器内部错误
- ⚠ `primary=401`: API返回未授权（这个是正常的，因为没有token）
- ✗ `alt=500`: 备用路径返回服务器内部错误

## 📊 架构说明

**GitLab部署架构：**
```
外部请求 → Nginx (80端口) → GitLab内置Nginx (127.0.0.1:8081) → GitLab应用
                ↓
          PostgreSQL (5432)
          Redis (6379)
```

## 🔧 快速诊断

### 方法1：运行自动诊断脚本（推荐）

```bash
cd /root/cloud-native-devops-platform
chmod +x scripts/gitlab-diagnosis.sh
./scripts/gitlab-diagnosis.sh
```

这个脚本会检查：
- ✓ 系统资源（内存、磁盘）
- ✓ GitLab服务状态
- ✓ PostgreSQL数据库
- ✓ Redis缓存
- ✓ Nginx配置
- ✓ 端口占用
- ✓ 网络连接
- ✓ 错误日志
- ✓ 配置文件

### 方法2：手动排查

## 🚨 常见问题及解决方案

### 问题1：数据库连接失败

**症状：**
- GitLab返回500错误
- 日志中出现 `PG::ConnectionBad` 或 `could not connect to server`

**检查：**
```bash
# 1. 检查PostgreSQL是否运行
systemctl status postgresql

# 2. 测试数据库连接
sudo -u postgres psql -c "SELECT version();"

# 3. 检查GitLab数据库
sudo -u postgres psql gitlabhq_production -c "SELECT COUNT(*) FROM users;"

# 4. 检查pg_hba.conf认证配置
cat /var/lib/pgsql/data/pg_hba.conf
```

**解决方案：**
```bash
# 1. 启动PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# 2. 如果认证失败，修复pg_hba.conf
# 编辑 /var/lib/pgsql/data/pg_hba.conf
# 确保有以下行：
local   all   all                 md5
host    all   all   127.0.0.1/32  md5

# 3. 重启PostgreSQL
systemctl restart postgresql

# 4. 重新配置GitLab
gitlab-ctl reconfigure
gitlab-ctl restart
```

### 问题2：Redis连接失败

**症状：**
- GitLab返回500错误
- 日志中出现 `Redis::CannotConnectError`

**检查：**
```bash
# 1. 检查Redis是否运行
systemctl status redis

# 2. 测试Redis连接
redis-cli ping

# 3. 检查Redis配置
grep -E "^bind|^port" /etc/redis.conf
```

**解决方案：**
```bash
# 1. 启动Redis
systemctl start redis
systemctl enable redis

# 2. 确保Redis监听127.0.0.1:6379
# 编辑 /etc/redis.conf
bind 127.0.0.1
port 6379

# 3. 重启服务
systemctl restart redis
gitlab-ctl restart
```

### 问题3：GitLab服务未完全启动

**症状：**
- 服务刚启动后返回500
- 过一段时间后恢复正常

**检查：**
```bash
# 1. 检查GitLab所有组件状态
gitlab-ctl status

# 2. 查看哪些组件未运行
gitlab-ctl status | grep -v "run:"

# 3. 检查就绪探针
curl -I http://127.0.0.1:8081/-/readiness
```

**解决方案：**
```bash
# 1. 等待GitLab完全启动（可能需要5-10分钟）
watch -n 5 'curl -I http://127.0.0.1:8081/-/readiness'

# 2. 如果长时间未就绪，重启GitLab
gitlab-ctl restart

# 3. 查看启动日志
gitlab-ctl tail
```

### 问题4：Nginx反向代理配置错误

**症状：**
- 直接访问8081正常，通过80端口500

**检查：**
```bash
# 1. 检查Nginx配置
nginx -t

# 2. 查看Nginx错误日志
tail -f /var/log/nginx/error.log

# 3. 测试内部连接
curl -I http://127.0.0.1:8081/

# 4. 测试外部连接
curl -I http://$(hostname -I | awk '{print $1}')/
```

**解决方案：**
```bash
# 1. 重新生成Nginx配置
ansible-playbook -i inventory/single-node.yml playbooks/05-cicd-setup.yml --tags nginx

# 2. 或手动修复 /etc/nginx/nginx.conf
# 确保有以下配置：
upstream gitlab {
    server 127.0.0.1:8081;
}

server {
    listen 80;
    location / {
        proxy_pass http://gitlab/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 3. 重启Nginx
systemctl restart nginx
```

### 问题5：磁盘空间不足

**症状：**
- 500错误
- 日志中出现 `No space left on device`

**检查：**
```bash
df -h
du -sh /var/opt/gitlab/*
du -sh /var/log/gitlab/*
```

**解决方案：**
```bash
# 1. 清理日志
find /var/log/gitlab -name "*.log" -mtime +7 -exec rm -f {} \;

# 2. 清理旧备份
find /var/opt/gitlab/backups -name "*.tar" -mtime +7 -exec rm -f {} \;

# 3. 清理Docker
docker system prune -a -f
```

### 问题6：内存不足

**症状：**
- GitLab组件频繁重启
- 系统响应缓慢

**检查：**
```bash
free -h
htop  # 或 top
```

**解决方案：**
```bash
# 1. 减少GitLab worker数量
# 编辑 /etc/gitlab/gitlab.rb
gitlab_rails['worker_processes'] = 2
gitlab_rails['worker_memory_limit_mb'] = 1024

# 2. 重新配置
gitlab-ctl reconfigure

# 3. 或者增加swap
dd if=/dev/zero of=/swapfile bs=1M count=4096
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

## 🔬 深度诊断命令

### 查看所有GitLab日志
```bash
# 实时查看所有日志
gitlab-ctl tail

# 查看特定服务日志
gitlab-ctl tail nginx
gitlab-ctl tail puma
gitlab-ctl tail postgresql

# 查看最近的错误
grep -i error /var/log/gitlab/gitlab-rails/production.log | tail -50
```

### 运行GitLab健康检查
```bash
# 完整的系统检查
gitlab-rake gitlab:check

# 检查环境
gitlab-rake gitlab:env:info

# 检查数据库
gitlab-rake gitlab:db:check
```

### 查看GitLab配置
```bash
# 查看当前配置
gitlab-ctl show-config

# 查看运行时配置
cat /opt/gitlab/embedded/service/gitlab-rails/config/database.yml
cat /opt/gitlab/embedded/service/gitlab-rails/config/redis.yml
```

## 🔄 完整重启流程

如果上述方法都不行，尝试完整重启：

```bash
# 1. 停止所有服务
gitlab-ctl stop
systemctl stop nginx
systemctl stop redis
systemctl stop postgresql

# 2. 清理临时文件
rm -rf /var/opt/gitlab/gitlab-rails/sockets/*
rm -rf /var/opt/gitlab/gitlab-rails/tmp/*

# 3. 按顺序启动服务
systemctl start postgresql
systemctl start redis
sleep 5
gitlab-ctl start
systemctl start nginx

# 4. 等待服务就绪
sleep 30

# 5. 验证
gitlab-ctl status
curl -I http://127.0.0.1:8081/-/readiness
```

## 📝 收集诊断信息

如果问题仍未解决，收集以下信息以便进一步分析：

```bash
# 创建诊断报告
mkdir -p /tmp/gitlab-diagnosis
cd /tmp/gitlab-diagnosis

# 1. 服务状态
gitlab-ctl status > gitlab-status.txt
systemctl status postgresql --no-pager > postgresql-status.txt
systemctl status redis --no-pager > redis-status.txt
systemctl status nginx --no-pager > nginx-status.txt

# 2. 日志
tail -500 /var/log/gitlab/gitlab-rails/production.log > rails-production.log
tail -500 /var/log/gitlab/puma/puma_stdout.log > puma.log 2>/dev/null || tail -500 /var/log/gitlab/unicorn/unicorn_stdout.log > unicorn.log
tail -500 /var/log/gitlab/nginx/error.log > nginx-error.log
tail -200 /var/log/nginx/error.log > system-nginx-error.log

# 3. 配置
cp /etc/gitlab/gitlab.rb gitlab.rb
cp /etc/nginx/nginx.conf nginx.conf

# 4. 系统信息
free -h > system-memory.txt
df -h > system-disk.txt
netstat -tuln > network-ports.txt 2>/dev/null || ss -tuln > network-ports.txt

# 5. 打包
cd /tmp
tar -czf gitlab-diagnosis.tar.gz gitlab-diagnosis/
echo "诊断信息已保存到: /tmp/gitlab-diagnosis.tar.gz"
```

## 🎯 针对你的情况的建议

基于错误信息 `root=500, internal=500, primary=401, alt=500`，最可能的原因是：

### 1. **数据库连接问题**（最可能）
```bash
# 立即检查
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql gitlabhq_production -c "\dt"
```

### 2. **GitLab服务未完全启动**
```bash
# 立即检查
gitlab-ctl status
curl -I http://127.0.0.1:8081/-/readiness
```

### 3. **配置文件错误**
```bash
# 立即检查
grep -E "^external_url|^nginx\['listen" /etc/gitlab/gitlab.rb
```

## 🚀 立即执行的诊断步骤

```bash
# 步骤1：运行诊断脚本
cd /root/cloud-native-devops-platform
./scripts/gitlab-diagnosis.sh > gitlab-diag.log 2>&1

# 步骤2：查看GitLab详细状态
gitlab-ctl status

# 步骤3：查看最近错误
tail -100 /var/log/gitlab/gitlab-rails/production.log | grep ERROR

# 步骤4：测试数据库
sudo -u postgres psql gitlabhq_production -c "SELECT COUNT(*) FROM users;"

# 步骤5：测试Redis
redis-cli ping

# 将以上输出发送给我，我可以帮你进一步分析
```

## 📞 需要更多帮助？

如果问题仍未解决，请提供：
1. `gitlab-diagnosis.sh` 脚本的完整输出
2. `/var/log/gitlab/gitlab-rails/production.log` 最后100行
3. `gitlab-ctl status` 的输出
4. 系统内存和磁盘使用情况


