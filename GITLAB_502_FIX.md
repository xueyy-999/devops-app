# GitLab 502 错误完整解决方案

## 🚨 问题描述

您在运行 `07-verification.yml` 时遇到以下错误：
```
GitLab 检查失败（root=502, internal=502, primary=502, alt=502)
```

**502 Bad Gateway** 错误表示：
- Nginx 反向代理无法连接到 GitLab 后端服务
- GitLab 的 Puma/Unicorn 工作进程没有运行或无法响应
- 可能的原因：数据库连接失败、Redis 连接失败、服务未启动、内存不足等

## 📊 架构说明

当前部署架构：
```
客户端请求
    ↓
外部 Nginx (0.0.0.0:80)
    ↓
反向代理到 GitLab 内置 Nginx (127.0.0.1:8081)
    ↓
GitLab Puma/Unicorn 进程
    ↓
PostgreSQL (127.0.0.1:5432) + Redis (127.0.0.1:6379)
```

## 🔧 快速修复（推荐）

### 方法 1：使用自动修复脚本

```bash
# SSH 登录到您的 CentOS 9 虚拟机
ssh root@your-vm-ip

# 进入项目目录
cd /root/cloud-native-devops-platform  # 或您的实际项目路径

# 添加执行权限
chmod +x quick-fix-gitlab-502.sh

# 运行修复脚本
./quick-fix-gitlab-502.sh
```

**这个脚本会自动：**
- ✅ 检查并启动 PostgreSQL
- ✅ 检查并启动 Redis
- ✅ 检查并修复 GitLab 服务
- ✅ 检查并启动外部 Nginx
- ✅ 等待 GitLab 完全启动（最多 10 分钟）
- ✅ 测试所有连接端点

**预计执行时间：** 5-15 分钟（取决于 GitLab 启动速度）

### 方法 2：手动排查和修复

如果自动脚本没有解决问题，请按以下步骤手动排查：

## 🔍 手动排查步骤

### 步骤 1：检查 PostgreSQL

```bash
# 检查服务状态
systemctl status postgresql

# 如果未运行，启动它
systemctl start postgresql
systemctl enable postgresql

# 测试连接
sudo -u postgres psql -c "SELECT version();"

# 检查 GitLab 数据库
sudo -u postgres psql -l | grep gitlabhq_production

# 如果数据库不存在，创建它
sudo -u postgres psql <<EOF
CREATE DATABASE gitlabhq_production;
CREATE USER gitlab WITH PASSWORD 'gitlab123';
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO gitlab;
ALTER DATABASE gitlabhq_production OWNER TO gitlab;
EOF

# 测试 GitLab 用户连接
sudo -u postgres psql -d gitlabhq_production -c "SELECT current_database();"
```

**常见问题：**
- 如果 PostgreSQL 无法启动：检查日志 `journalctl -u postgresql -n 50`
- 如果连接被拒绝：检查 `/var/lib/pgsql/data/pg_hba.conf` 配置

### 步骤 2：检查 Redis

```bash
# 检查服务状态
systemctl status redis

# 如果未运行，启动它
systemctl start redis
systemctl enable redis

# 测试连接
redis-cli ping
# 应该返回：PONG

# 检查 Redis 配置
grep -E "^bind|^port" /etc/redis.conf
```

**期望配置：**
```
bind 127.0.0.1
port 6379
```

### 步骤 3：检查 GitLab 服务

```bash
# 查看所有 GitLab 服务状态
gitlab-ctl status

# 如果有服务 down，查看具体哪个
gitlab-ctl status | grep -v "run:"

# 重启所有服务
gitlab-ctl restart

# 如果完全无法启动，重新配置
gitlab-ctl reconfigure

# 查看实时日志
gitlab-ctl tail
```

**重点检查的服务：**
- `puma` 或 `unicorn` - GitLab 应用服务器（最关键）
- `nginx` - GitLab 内置 Nginx
- `postgresql` - 如果使用内置数据库
- `redis` - 如果使用内置 Redis

### 步骤 4：检查 GitLab 配置文件

```bash
# 查看配置
cat /etc/gitlab/gitlab.rb | grep -v "^#" | grep -v "^$"

# 确认关键配置
grep "^external_url" /etc/gitlab/gitlab.rb
grep "^nginx\['listen" /etc/gitlab/gitlab.rb
grep "^gitlab_rails\['db_" /etc/gitlab/gitlab.rb | grep -v password
grep "^gitlab_rails\['redis_" /etc/gitlab/gitlab.rb
```

**期望的配置：**
```ruby
external_url 'http://YOUR_IP'
nginx['listen_port'] = 8081
nginx['listen_addresses'] = ['127.0.0.1']

postgresql['enable'] = false
gitlab_rails['db_host'] = '127.0.0.1'
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab123'

redis['enable'] = false
gitlab_rails['redis_host'] = '127.0.0.1'
gitlab_rails['redis_port'] = 6379
```

如果配置不正确，修改后执行：
```bash
gitlab-ctl reconfigure
gitlab-ctl restart
```

### 步骤 5：检查外部 Nginx

```bash
# 检查服务状态
systemctl status nginx

# 启动服务
systemctl start nginx
systemctl enable nginx

# 测试配置
nginx -t

# 查看配置
cat /etc/nginx/nginx.conf

# 查看错误日志
tail -50 /var/log/nginx/error.log
```

**检查 upstream 配置：**
```nginx
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
```

### 步骤 6：等待 GitLab 启动

**重要：** GitLab 首次启动或重启后需要 **5-10 分钟** 才能完全就绪！

```bash
# 方法 1：监控端口
watch -n 2 'netstat -tuln | grep -E ":(80|8081) "'

# 方法 2：轮询就绪探针
watch -n 5 'curl -I http://127.0.0.1:8081/-/readiness'

# 方法 3：查看实时日志
gitlab-ctl tail puma
```

**等待直到：**
- `8081` 端口开始监听
- 就绪探针返回 `HTTP/1.1 200 OK`
- 日志中没有错误

### 步骤 7：测试连接

```bash
# 获取 IP 地址
IP=$(hostname -I | awk '{print $1}')

# 测试 1：GitLab 内部
curl -I http://127.0.0.1:8081/

# 测试 2：通过外部 Nginx
curl -I http://$IP/

# 测试 3：API 端点
curl -I http://$IP/api/v4/version

# 测试 4：就绪探针
curl http://127.0.0.1:8081/-/readiness
```

**期望结果：**
- 内部测试：`HTTP/1.1 302 Found` 或 `200 OK`
- 外部测试：`HTTP/1.1 302 Found` 或 `200 OK`
- API 测试：`HTTP/1.1 401 Unauthorized`（正常，因为没有 token）
- 就绪探针：`HTTP/1.1 200 OK` 和 JSON 响应

## 🚨 常见错误及解决方案

### 错误 1：PostgreSQL 连接失败

**症状：**
```
PG::ConnectionBad: could not connect to server
```

**解决：**
```bash
# 1. 检查 PostgreSQL 是否运行
systemctl status postgresql

# 2. 检查认证配置
sudo vi /var/lib/pgsql/data/pg_hba.conf

# 确保包含以下行（在其他规则之前）：
local   all   all                 md5
host    all   all   127.0.0.1/32  md5
host    all   all   ::1/128       md5

# 3. 重启 PostgreSQL
systemctl restart postgresql

# 4. 重新配置 GitLab
gitlab-ctl reconfigure
gitlab-ctl restart
```

### 错误 2：Redis 连接失败

**症状：**
```
Redis::CannotConnectError: Error connecting to Redis
```

**解决：**
```bash
# 1. 确保 Redis 运行
systemctl start redis
systemctl enable redis

# 2. 测试连接
redis-cli ping

# 3. 如果失败，检查配置
sudo vi /etc/redis.conf

# 确保：
bind 127.0.0.1
port 6379

# 4. 重启 Redis
systemctl restart redis

# 5. 重启 GitLab
gitlab-ctl restart
```

### 错误 3：端口 8081 未监听

**症状：**
```bash
netstat -tuln | grep 8081
# 没有输出
```

**解决：**
```bash
# 1. 检查配置
grep "listen_port" /etc/gitlab/gitlab.rb

# 应该是：
# nginx['listen_port'] = 8081
# nginx['listen_addresses'] = ['127.0.0.1']

# 2. 检查 GitLab nginx 服务
gitlab-ctl status nginx

# 3. 查看日志
gitlab-ctl tail nginx

# 4. 重启 nginx
gitlab-ctl restart nginx

# 5. 如果仍然失败，重新配置
gitlab-ctl reconfigure
```

### 错误 4：Puma/Unicorn 未运行

**症状：**
```bash
gitlab-ctl status
# puma: down
```

**解决：**
```bash
# 1. 尝试启动
gitlab-ctl start puma

# 2. 如果失败，查看日志
gitlab-ctl tail puma

# 常见原因：
# - 数据库连接失败
# - Redis 连接失败
# - 内存不足
# - 配置错误

# 3. 检查内存
free -h

# 4. 如果内存不足，增加 swap
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 5. 重启 GitLab
gitlab-ctl restart
```

### 错误 5：外部 Nginx 502

**症状：**
- 直接访问 `http://127.0.0.1:8081` 正常（200/302）
- 通过外部 Nginx `http://YOUR_IP` 返回 502

**解决：**
```bash
# 1. 检查 upstream 配置
grep -A 5 "upstream gitlab" /etc/nginx/nginx.conf

# 2. 测试 Nginx 配置
nginx -t

# 3. 查看 Nginx 错误日志
tail -50 /var/log/nginx/error.log

# 常见错误：
# - "connect() failed (111: Connection refused)"
#   → GitLab 内置 Nginx 未运行
# - "upstream timed out"
#   → GitLab 响应太慢，增加超时时间

# 4. 如果配置错误，重新生成
cd /root/cloud-native-devops-platform
ansible-playbook -i inventory/single-node.yml \
  playbooks/05-cicd-setup.yml \
  --tags nginx

# 5. 重启 Nginx
systemctl restart nginx
```

## 🔬 深度诊断

### 查看完整日志

```bash
# GitLab 应用日志
tail -200 /var/log/gitlab/gitlab-rails/production.log

# Puma 日志
tail -100 /var/log/gitlab/puma/puma_stdout.log
tail -100 /var/log/gitlab/puma/puma_stderr.log

# GitLab Nginx 日志
tail -100 /var/log/gitlab/nginx/error.log
tail -100 /var/log/gitlab/nginx/gitlab_access.log

# 系统 Nginx 日志
tail -100 /var/log/nginx/error.log
tail -100 /var/log/nginx/access.log

# PostgreSQL 日志
tail -100 /var/lib/pgsql/data/log/postgresql-*.log

# 实时监控所有日志
gitlab-ctl tail
```

### 运行健康检查

```bash
# GitLab 完整健康检查
gitlab-rake gitlab:check SANITIZE=true

# 检查环境
gitlab-rake gitlab:env:info

# 检查数据库迁移
gitlab-rake db:migrate:status

# 检查配置
gitlab-ctl show-config
```

### 检查系统资源

```bash
# 内存使用
free -h

# 磁盘使用
df -h

# GitLab 占用的磁盘空间
du -sh /var/opt/gitlab/*
du -sh /var/log/gitlab/*

# 进程状态
ps aux | grep -E "(puma|unicorn|gitlab)"

# 端口监听
netstat -tulnp | grep -E "(80|8081|5432|6379)"
```

## 🔄 完全重置（最后手段）

如果以上方法都无效，可以完全重置 GitLab：

```bash
# ⚠️ 警告：这会清除所有 GitLab 数据！

# 1. 停止所有服务
gitlab-ctl stop

# 2. 备份配置
cp /etc/gitlab/gitlab.rb /root/gitlab.rb.backup

# 3. 清理数据（可选，会删除所有数据）
# rm -rf /var/opt/gitlab/*
# rm -rf /var/log/gitlab/*

# 4. 重新配置
gitlab-ctl reconfigure

# 5. 启动服务
gitlab-ctl start

# 6. 等待 10 分钟
sleep 600

# 7. 检查状态
gitlab-ctl status
curl -I http://127.0.0.1:8081/-/readiness
```

## ✅ 验证成功

当所有检查通过后，重新运行验证脚本：

```bash
cd /root/cloud-native-devops-platform
ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml
```

**预期输出：**
```
TASK [断言GitLab可达] ********************************************
ok: [devops-node]
```

## 📞 获取帮助

如果问题仍未解决，请收集以下信息：

```bash
# 运行完整诊断
./quick-fix-gitlab-502.sh > gitlab-diagnosis.log 2>&1

# 收集日志
mkdir -p /tmp/gitlab-logs
cp /var/log/gitlab/gitlab-rails/production.log /tmp/gitlab-logs/
cp /var/log/gitlab/puma/puma_stdout.log /tmp/gitlab-logs/ 2>/dev/null
cp /var/log/gitlab/nginx/error.log /tmp/gitlab-logs/
cp /var/log/nginx/error.log /tmp/gitlab-logs/system-nginx-error.log
cp /etc/gitlab/gitlab.rb /tmp/gitlab-logs/
cp /etc/nginx/nginx.conf /tmp/gitlab-logs/

# 打包
cd /tmp
tar -czf gitlab-debug-$(date +%Y%m%d-%H%M%S).tar.gz gitlab-logs/

echo "调试包已创建："
ls -lh /tmp/gitlab-debug-*.tar.gz
```

然后提供：
1. `gitlab-diagnosis.log` 的内容
2. `gitlab-ctl status` 的输出
3. `free -h` 和 `df -h` 的输出
4. 调试包 `gitlab-debug-*.tar.gz`

## 🎯 快速参考

| 问题 | 命令 | 预期结果 |
|------|------|----------|
| PostgreSQL 运行？ | `systemctl status postgresql` | `active (running)` |
| Redis 运行？ | `redis-cli ping` | `PONG` |
| GitLab 运行？ | `gitlab-ctl status` | 所有服务 `run:` |
| 8081 监听？ | `netstat -tuln \| grep 8081` | `127.0.0.1:8081` |
| 80 监听？ | `netstat -tuln \| grep :80` | `0.0.0.0:80` |
| GitLab 就绪？ | `curl http://127.0.0.1:8081/-/readiness` | HTTP 200 + JSON |
| API 可达？ | `curl -I http://YOUR_IP/api/v4/version` | HTTP 401 |

## 📚 相关文档

- [GITLAB_TROUBLESHOOTING.md](GITLAB_TROUBLESHOOTING.md) - 500 错误排查
- [GITLAB_FIX_SUMMARY.md](GITLAB_FIX_SUMMARY.md) - 修复总结
- [scripts/gitlab-diagnosis.sh](scripts/gitlab-diagnosis.sh) - 诊断脚本
- [quick-fix-gitlab.sh](quick-fix-gitlab.sh) - 快速修复脚本

---

**最后更新：** 2025-10-14
**适用版本：** CentOS 9 + GitLab CE 16.0.0

