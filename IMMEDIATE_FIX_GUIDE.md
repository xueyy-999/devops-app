# GitLab 502 错误 - 立即修复指南

## 🚨 当前问题

```
GitLab 检查失败（root=502, internal=502, primary=502, alt=502)
```

**502 Bad Gateway** = Nginx无法连接到GitLab后端

## 🎯 最可能的原因（按概率排序）

1. **SELinux Enforcing** ⭐最可能 (90%)
2. **PostgreSQL连接失败** (60%)
3. **Redis连接失败** (40%)
4. **GitLab服务未完全启动** (30%)

---

## ⚡ 立即执行（3步修复）

### 步骤1: 上传修复文件（Windows）

```powershell
# 在Windows PowerShell中执行
cd D:\3

# 方法A: 使用上传脚本（推荐）
.\upload-fixes.ps1

# 方法B: 手动上传关键文件
scp PROJECT_ISSUES_COMPLETE_ANALYSIS.md root@192.168.76.141:/root/cloud-native-devops-platform/
scp quick-fix-gitlab-502.sh root@192.168.76.141:/root/cloud-native-devops-platform/
scp playbooks\00-selinux-check.yml root@192.168.76.141:/root/cloud-native-devops-platform/playbooks/
scp playbooks\00-resource-check.yml root@192.168.76.141:/root/cloud-native-devops-platform/playbooks/
```

### 步骤2: 运行502修复脚本（Linux虚拟机）

```bash
# SSH到虚拟机
ssh root@192.168.76.141

# 进入项目目录
cd /root/cloud-native-devops-platform

# 添加执行权限
chmod +x quick-fix-gitlab-502.sh scripts/gitlab-diagnosis.sh

# 运行502修复脚本（这是关键！）
./quick-fix-gitlab-502.sh
```

**这个脚本会自动：**
- ✅ 检查并修复SELinux（最关键）
- ✅ 检查并启动PostgreSQL
- ✅ 检查并启动Redis
- ✅ 修复数据库认证配置
- ✅ 重启GitLab所有组件
- ✅ 检查并启动Nginx
- ✅ 等待GitLab完全就绪（最多10分钟）
- ✅ 测试所有端点

**预计执行时间**: 10-15分钟

### 步骤3: 验证修复结果

```bash
# 1. 手动测试GitLab连接
curl -I http://127.0.0.1:8081/-/readiness
# 应该返回: HTTP/1.1 200 OK

curl -I http://192.168.76.141/
# 应该返回: HTTP/1.1 200 OK 或 302 Found

# 2. 如果上面成功，运行完整验证
ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml

# 3. 查看GitLab初始密码
cat /etc/gitlab/initial_root_password

# 4. 在浏览器访问
# http://192.168.76.141/
# 用户名: root
# 密码: 见上面文件内容
```

---

## 🔧 如果自动修复失败

### 诊断A: 检查SELinux（最关键）

```bash
# 1. 检查状态
getenforce
# 如果是 Enforcing → 这就是问题！

# 2. 立即临时禁用
sudo setenforce 0

# 3. 永久禁用
sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config

# 4. 验证
getenforce  # 应该返回: Permissive

# 5. 重启GitLab
gitlab-ctl restart

# 6. 等待5分钟
sleep 300

# 7. 再次测试
curl -I http://127.0.0.1:8081/-/readiness
```

### 诊断B: 检查PostgreSQL

```bash
# 1. 检查服务
systemctl status postgresql

# 2. 如果未运行
systemctl start postgresql
systemctl enable postgresql

# 3. 测试连接
sudo -u postgres psql -c "SELECT version();"

# 4. 检查GitLab数据库
sudo -u postgres psql -l | grep gitlabhq

# 5. 如果数据库不存在，创建它
sudo -u postgres psql <<EOF
CREATE DATABASE gitlabhq_production;
CREATE USER gitlab WITH PASSWORD 'gitlab123';
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO gitlab;
ALTER DATABASE gitlabhq_production OWNER TO gitlab;
EOF

# 6. 测试GitLab用户连接
sudo -u postgres psql -h 127.0.0.1 -U gitlab -d gitlabhq_production -W
# 密码: gitlab123

# 7. 如果认证失败，临时改为trust
sudo sed -i 's/md5/trust/g' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
gitlab-ctl restart
```

### 诊断C: 检查Redis

```bash
# 1. 检查服务
systemctl status redis

# 2. 如果未运行
systemctl start redis
systemctl enable redis

# 3. 测试连接
redis-cli ping
# 应该返回: PONG

# 4. 检查配置
grep -E "^bind|^port" /etc/redis.conf
# 应该是:
# bind 127.0.0.1
# port 6379

# 5. 如果不正确，修复
sudo sed -i 's/^bind.*/bind 127.0.0.1/' /etc/redis.conf
sudo sed -i 's/^port.*/port 6379/' /etc/redis.conf
sudo systemctl restart redis
gitlab-ctl restart
```

### 诊断D: 检查GitLab服务

```bash
# 1. 查看所有组件状态
gitlab-ctl status

# 2. 如果有down的组件
gitlab-ctl restart

# 3. 查看实时日志
gitlab-ctl tail puma
# Ctrl+C 退出

# 4. 查看错误日志
tail -100 /var/log/gitlab/gitlab-rails/production.log | grep -i error

# 5. 如果看到"PG::ConnectionBad" → PostgreSQL问题
# 6. 如果看到"Redis::CannotConnectError" → Redis问题
# 7. 如果看到"Permission denied" → SELinux问题
```

### 诊断E: 完整重启流程

```bash
# 1. 停止所有服务
gitlab-ctl stop
systemctl stop nginx
systemctl stop redis
systemctl stop postgresql

# 2. 禁用SELinux
setenforce 0

# 3. 按顺序启动
systemctl start postgresql
sleep 5
systemctl start redis
sleep 5
gitlab-ctl start
sleep 30
systemctl start nginx

# 4. 等待就绪
watch -n 5 'curl -I http://127.0.0.1:8081/-/readiness'
# 等到看到 200 OK 后按 Ctrl+C

# 5. 测试
curl -I http://192.168.76.141/
```

---

## 📊 修复成功的标志

```bash
# 1. SELinux状态
$ getenforce
Permissive 或 Disabled  ✓

# 2. 所有服务运行
$ systemctl status postgresql redis nginx gitlab-runsvdir.service
● Active: active (running)  ✓

# 3. GitLab所有组件运行
$ gitlab-ctl status
run: gitaly: (pid 12345) 123s; run: ...  ✓
run: gitlab-workhorse: (pid 12346) 123s; run: ...  ✓
run: nginx: (pid 12347) 123s; run: ...  ✓
run: puma: (pid 12348) 123s; run: ...  ✓
...全部是 run:  ✓

# 4. 就绪探针返回200
$ curl -I http://127.0.0.1:8081/-/readiness
HTTP/1.1 200 OK  ✓

# 5. 根路径返回200或302
$ curl -I http://192.168.76.141/
HTTP/1.1 200 OK 或 HTTP/1.1 302 Found  ✓

# 6. API返回200或401
$ curl -I http://192.168.76.141/api/v4/version
HTTP/1.1 200 OK 或 HTTP/1.1 401 Unauthorized  ✓
(401是正常的，表示需要认证)
```

---

## 🎓 为什么会出现502错误？

### SELinux阻止通信

SELinux (Security-Enhanced Linux) 是一个安全机制，默认会阻止进程间通信。

当SELinux处于Enforcing状态时：
- ✗ GitLab Puma无法连接PostgreSQL socket
- ✗ GitLab无法连接Redis
- ✗ Nginx无法代理到GitLab内置Nginx
- ✗ 结果：所有请求返回502

**解决方案**: 禁用SELinux或配置SELinux策略

### 数据库连接失败

PostgreSQL认证从trust切换到md5时：
- ✗ GitLab配置的密码不匹配
- ✗ pg_hba.conf配置错误
- ✗ PostgreSQL未完全启动
- ✗ 结果：Puma进程启动失败，返回502

**解决方案**: 临时使用trust认证，或确保密码正确

### 服务启动顺序

正确的启动顺序：
1. PostgreSQL → 必须完全就绪
2. Redis → 必须可连接
3. GitLab → 所有组件启动
4. Nginx → 最后启动

如果顺序错误或启动过快：
- ✗ GitLab在DB未就绪时启动
- ✗ Puma进程无法初始化
- ✗ 结果：502

**解决方案**: 按顺序启动并等待

---

## 📞 如果问题仍未解决

收集诊断信息：

```bash
# 1. 运行完整诊断
./scripts/gitlab-diagnosis.sh > /tmp/gitlab-diagnosis.txt 2>&1

# 2. 收集关键日志
tar -czf /tmp/gitlab-logs-$(date +%Y%m%d-%H%M%S).tar.gz \
    /var/log/gitlab/gitlab-rails/production.log \
    /var/log/gitlab/puma/puma_stdout.log \
    /var/log/gitlab/nginx/error.log \
    /var/log/nginx/error.log \
    /tmp/gitlab-diagnosis.txt

# 3. 下载到Windows
# 在Windows PowerShell中：
scp root@192.168.76.141:/tmp/gitlab-logs-*.tar.gz D:\3\

# 4. 提供以下信息
echo "=== 系统信息 ===" > /tmp/system-info.txt
getenforce >> /tmp/system-info.txt
echo "" >> /tmp/system-info.txt
free -h >> /tmp/system-info.txt
echo "" >> /tmp/system-info.txt
df -h >> /tmp/system-info.txt
echo "" >> /tmp/system-info.txt
gitlab-ctl status >> /tmp/system-info.txt
```

然后查看详细文档：`PROJECT_ISSUES_COMPLETE_ANALYSIS.md`

---

## ✅ 快速检查清单

在运行修复脚本前/后检查：

- [ ] SELinux是Permissive或Disabled
- [ ] PostgreSQL服务运行中
- [ ] Redis服务运行中
- [ ] GitLab服务运行中
- [ ] Nginx服务运行中
- [ ] GitLab所有组件状态为"run"
- [ ] 可用内存 > 2GB
- [ ] 可用磁盘 > 10GB
- [ ] http://127.0.0.1:8081/-/readiness 返回200
- [ ] http://192.168.76.141/ 返回200或302

---

## 🚀 修复后下一步

1. **重新运行验证脚本**
   ```bash
   ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml
   ```

2. **访问GitLab**
   - URL: http://192.168.76.141/
   - 用户名: root
   - 密码: `cat /etc/gitlab/initial_root_password`

3. **修改root密码**
   - 首次登录后立即修改密码
   - 密码文件24小时后会自动删除

4. **建议重启系统**（如果修改了SELinux配置）
   ```bash
   reboot
   ```

5. **定期维护**
   - 每周清理Docker: `docker system prune -a -f`
   - 每月清理日志: `find /var/log -name "*.log" -mtime +30 -delete`
   - 监控资源: `htop` 或 `watch -n 5 'free -h && df -h'`

---

**祝修复顺利！** 🎉

如有问题，参考完整分析文档：`PROJECT_ISSUES_COMPLETE_ANALYSIS.md`

