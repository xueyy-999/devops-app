# 云原生DevOps平台 - 完整问题分析与修复方案

## 📊 执行摘要

**分析时间**：2025-10-28  
**项目状态**：部署过程中遇到多个关键问题  
**主要问题**：GitLab 502 Bad Gateway错误  
**根本原因**：配置不一致、SELinux干扰、服务依赖顺序、资源不足

---

## 🔴 当前紧急问题

### 问题1: GitLab 502 错误（高优先级）

**症状**：
```
GitLab 检查失败（root=502, internal=502, primary=502, alt=502)
```

**根本原因分析**：
1. ✗ **SELinux未正确禁用**（最可能）
   - `01-common-setup.yml` 设置禁用SELinux后需要重启
   - 但05-cicd-setup.yml在安装GitLab时没有验证SELinux状态
   - 如果系统未重启或SELinux恢复Enforcing，会阻止GitLab访问PostgreSQL

2. ✗ **数据库认证配置问题**
   - PostgreSQL在部署时先设置为trust，然后改回md5
   - GitLab可能在trust→md5切换期间无法连接
   - 密码认证可能失败

3. ✗ **服务启动顺序问题**
   - PostgreSQL → Redis → GitLab → Nginx的启动顺序未严格保证
   - GitLab在DB未完全就绪时启动会导致502

4. ✗ **资源不足**
   - GitLab要求至少4GB内存，单节点部署资源可能不足
   - Puma进程可能因内存不足被OOM killer杀死

---

## 📋 完整问题清单

### 一、配置一致性问题

#### 1.1 端口配置冲突
| 文件 | 配置项 | 值 | 问题 |
|------|--------|----|----|
| `playbooks/05-cicd-setup.yml` | `gitlab_port` | 8081 | ✗ 与inventory不一致 |
| `inventory/single-node.yml` | `gitlab_port` | 80 | ✗ 与playbook不一致 |
| **修复状态** | | | ✅ 已修复（添加注释说明） |

#### 1.2 变量引用不一致
```yaml
# playbooks/05-cicd-setup.yml
gitlab_port: 8081  # GitLab内置Nginx端口
jenkins_port: 8080
harbor_port: 5000  # Harbor内部端口

# inventory/single-node.yml  
gitlab_port: 80    # 外部Nginx端口（已修复）
jenkins_port: 8080
harbor_port: 80    # 外部Nginx端口（已修复）
```

**影响**：验证脚本构建错误的URL导致验证失败  
**修复状态**：✅ 已在inventory中添加 `gitlab_internal_port` 和 `harbor_internal_port`

### 二、SELinux干扰问题（关键问题）

#### 2.1 SELinux禁用流程问题
```yaml
# playbooks/01-common-setup.yml (行120-138)
- name: 禁用SELinux
  selinux:
    state: disabled
  when: selinux_status.stdout != "Disabled"

- name: 重启系统以应用SELinux更改
  reboot:
  when: selinux_status.stdout != "Disabled"
```

**问题**：
- ✗ SELinux禁用需要重启，但后续playbook不检查是否已禁用
- ✗ 如果用户跳过重启或SELinux配置恢复，会导致所有服务异常
- ✗ GitLab 502错误最可能就是SELinux阻止了数据库连接

**影响**：
- PostgreSQL连接被拒绝
- Redis无法绑定
- GitLab Puma进程无法访问socket
- Nginx反向代理被阻止

#### 2.2 缺少SELinux验证
**所有后续playbook缺少SELinux检查**：
- `02-docker-setup.yml` - 无检查
- `03-kubernetes-fixed.yml` - 无检查
- `04-monitoring-setup.yml` - 无检查
- `05-cicd-setup.yml` - 无检查 ❗最关键
- `07-verification.yml` - 无检查

### 三、数据库配置问题

#### 3.1 PostgreSQL认证切换问题
```yaml
# playbooks/05-cicd-setup.yml (行69-78)
- name: 在 pg_hba.conf 顶部前置 trust
  blockinfile:
    block: |
      local   all   all                 trust
      host    all   all   127.0.0.1/32  trust

# ... GitLab安装 ...

# playbooks/05-cicd-setup.yml (行180-185)
- name: 将临时 trust 改回 md5
  replace:
    regexp: '\btrust\b'
    replace: 'md5'
```

**问题**：
- ✗ 从trust切换到md5后，GitLab可能无法连接
- ✗ GitLab配置中的密码是 `gitlab123`，但可能不匹配
- ✗ 没有验证切换后GitLab能否连接

**影响**：导致GitLab 502错误

#### 3.2 缺少数据库连接验证
```bash
# 应该在切换md5后立即验证
sudo -u postgres psql -h 127.0.0.1 -U gitlab -d gitlabhq_production -W
```

### 四、服务依赖和启动顺序问题

#### 4.1 GitLab启动依赖链
```
PostgreSQL (5432) → 必须完全就绪
    ↓
Redis (6379) → 必须完全就绪
    ↓
GitLab Puma → 需要连接DB和Redis
    ↓
GitLab Nginx (8081) → 需要Puma就绪
    ↓
外部 Nginx (80) → 需要GitLab Nginx就绪
```

**当前问题**：
```yaml
# playbooks/05-cicd-setup.yml
- name: 启动并启用PostgreSQL  # 启动但不等待就绪
- name: 启动并启用Redis       # 启动但不等待就绪
- name: 启动GitLab           # 立即启动，可能DB/Redis未就绪
- name: 启动并启用Nginx      # 立即启动，可能GitLab未就绪
```

**缺失的等待机制**：
- ✗ 没有等待PostgreSQL完全就绪（可以接受连接）
- ✗ 没有等待Redis完全就绪（PING返回PONG）
- ✗ GitLab `gitlab-ctl reconfigure` 后没有等待所有组件启动
- ✗ Nginx启动时没有验证上游服务可用

#### 4.2 当前有的等待机制（不完整）
```yaml
# playbooks/05-cicd-setup.yml (行448-473)
- name: 等待 GitLab 内置 Nginx 8081 监听
  wait_for:
    host: 127.0.0.1
    port: 8081
    timeout: 600

- name: 轮询 GitLab 内部就绪（/-/readiness）
  uri:
    url: "http://127.0.0.1:8081/-/readiness"
  retries: 30
  delay: 10
```

**问题**：这些等待在GitLab启动后，但不检查依赖服务

### 五、资源配置问题

#### 5.1 GitLab资源配置不足
```ruby
# templates/gitlab.rb.j2 (行45-48)
gitlab_rails['worker_processes'] = 2
gitlab_rails['worker_timeout'] = 60
gitlab_rails['worker_memory_limit_mb'] = 1024
```

**问题**：
- ✗ GitLab官方推荐至少4GB内存，但配置仅1GB per worker
- ✗ 单节点部署运行所有服务（K8s + 监控 + CI/CD），内存压力大
- ✗ 没有配置swap，OOM风险高

#### 5.2 单节点资源分配
```yaml
# 单节点上运行的服务：
- Kubernetes (etcd, apiserver, scheduler, controller, kubelet)
- Docker/Containerd
- Prometheus (内存消耗大)
- Grafana
- Alertmanager
- PostgreSQL
- Redis
- GitLab (Puma, Sidekiq, Gitaly, Workhorse)
- Jenkins
- Harbor
- Nginx
```

**预估资源需求**：
| 服务 | CPU | 内存 |
|------|-----|------|
| Kubernetes | 2核 | 2GB |
| GitLab | 4核 | 4GB |
| PostgreSQL | 1核 | 1GB |
| Redis | 0.5核 | 512MB |
| Prometheus | 1核 | 2GB |
| Harbor | 2核 | 4GB |
| 其他 | 1核 | 2GB |
| **总计** | **11.5核** | **15.5GB** |

**实际配置**：可能远低于需求

### 六、错误处理和重试机制问题

#### 6.1 缺少重试机制
```yaml
# 应该添加重试但没有的关键任务：
- PostgreSQL数据库创建
- Redis连接验证
- GitLab reconfigure（可能因网络问题失败）
- Harbor下载和安装
- Docker镜像拉取
```

#### 6.2 错误处理不完善
```yaml
# playbooks/05-cicd-setup.yml
- name: 安装GitLab CE
  dnf:
    name: gitlab-ce-{{ gitlab_version }}
  # ✗ 如果版本不存在会直接失败，无fallback
  # ✗ 无重试机制
  # ✗ 失败后不清理
```

### 七、验证和健康检查问题

#### 7.1 缺失的健康检查
**在服务启动后应该检查但没有检查的**：
- ✗ PostgreSQL: 能否接受TCP连接
- ✗ PostgreSQL: GitLab用户能否登录
- ✗ Redis: PING命令响应
- ✗ GitLab: 所有组件状态 (`gitlab-ctl status`)
- ✗ GitLab: 数据库迁移是否完成
- ✗ Nginx: 配置语法验证（在启动前）
- ✗ Nginx: 上游服务连通性

#### 7.2 验证脚本问题已修复
```yaml
# playbooks/07-verification.yml
# ✅ 已修复URL构建逻辑
# ✅ 已添加详细错误信息
# ✅ 已添加诊断建议
```

### 八、日志和调试问题

#### 8.1 缺少日志收集
**部署失败时没有自动收集的关键日志**：
- PostgreSQL日志
- Redis日志
- GitLab所有组件日志
- Nginx错误日志
- 系统日志 (journalctl)

#### 8.2 调试信息不足
**错误消息缺少的上下文**：
- 当前SELinux状态
- 当前内存使用
- 当前磁盘使用
- 服务启动顺序和时间戳

---

## 🛠️ 完整修复方案

### 紧急修复（立即执行）

#### 修复1: SELinux问题（最关键）

**创建SELinux检查和修复任务**：

```yaml
# 添加到 playbooks/05-cicd-setup.yml 开头（第29行后）
    # 0. 验证SELinux已禁用（关键！）
    - name: 检查SELinux状态
      command: getenforce
      register: selinux_check
      changed_when: false
      failed_when: false

    - name: 显示SELinux状态
      debug:
        msg: "SELinux当前状态: {{ selinux_check.stdout }}"

    - name: 断言SELinux必须禁用
      assert:
        that:
          - selinux_check.stdout == "Disabled" or selinux_check.stdout == "Permissive"
        fail_msg: |
          ❌ SELinux仍处于Enforcing状态！
          
          SELinux会阻止GitLab访问PostgreSQL和Redis，导致502错误。
          
          请执行以下步骤：
          1. 临时关闭：setenforce 0
          2. 永久关闭：编辑/etc/selinux/config，设置SELINUX=disabled
          3. 重启系统：reboot
          4. 验证：getenforce 应该返回 Disabled
          
          然后重新运行部署脚本。
        success_msg: "✓ SELinux已正确禁用"
```

#### 修复2: 数据库连接验证

```yaml
# 添加到 playbooks/05-cicd-setup.yml (在改回md5后，第191行后)
    - name: 等待PostgreSQL完全就绪
      wait_for:
        host: 127.0.0.1
        port: 5432
        timeout: 60
        delay: 2

    - name: 验证PostgreSQL连接（postgres用户）
      postgresql_ping:
        login_host: 127.0.0.1
        login_user: postgres
      register: pg_ping
      retries: 5
      delay: 3
      until: pg_ping is succeeded

    - name: 验证GitLab数据库用户连接（md5认证）
      postgresql_query:
        login_host: 127.0.0.1
        login_user: gitlab
        login_password: "{{ vault_gitlab_db_password | default('gitlab123') }}"
        db: gitlabhq_production
        query: SELECT 1 as test
      register: gitlab_db_test
      retries: 5
      delay: 3
      until: gitlab_db_test is succeeded
      failed_when: false

    - name: 显示数据库连接测试结果
      debug:
        msg: |
          PostgreSQL连接测试:
          - postgres用户: {{ 'OK' if pg_ping is succeeded else 'FAILED' }}
          - gitlab用户: {{ 'OK' if gitlab_db_test is succeeded else 'FAILED' }}

    - name: 如果GitLab用户连接失败，回滚到trust
      block:
        - name: 恢复trust认证
          replace:
            path: "{{ hba_file }}"
            regexp: '\bmd5\b'
            replace: 'trust'

        - name: 重启PostgreSQL
          systemd:
            name: postgresql
            state: restarted

        - name: 等待PostgreSQL重启
          wait_for:
            host: 127.0.0.1
            port: 5432
            timeout: 30

        - name: 重新测试连接
          postgresql_query:
            login_host: 127.0.0.1
            login_user: gitlab
            db: gitlabhq_production
            query: SELECT 1 as test
          register: gitlab_db_test_retry

        - name: 断言数据库连接成功
          assert:
            that: gitlab_db_test_retry is succeeded
            fail_msg: "GitLab数据库连接失败！请检查PostgreSQL配置和日志"
      when: gitlab_db_test is failed
```

#### 修复3: Redis验证

```yaml
# 添加到 playbooks/05-cicd-setup.yml (第125行后)
    - name: 等待Redis完全就绪
      wait_for:
        host: 127.0.0.1
        port: 6379
        timeout: 30
        delay: 2

    - name: 验证Redis连接
      command: redis-cli -h 127.0.0.1 -p 6379 ping
      register: redis_ping
      retries: 5
      delay: 3
      until: redis_ping.stdout == "PONG"
      changed_when: false

    - name: 显示Redis状态
      debug:
        msg: "Redis连接: {{ 'OK' if redis_ping.stdout == 'PONG' else 'FAILED' }}"
```

#### 修复4: GitLab服务验证增强

```yaml
# 替换 playbooks/05-cicd-setup.yml (第174-177行)
    - name: 启动GitLab（第一次配置）
      shell: |
        set -e
        gitlab-ctl reconfigure 2>&1 | tee /var/log/gitlab-reconfigure.log
        gitlab-ctl start 2>&1 | tee /var/log/gitlab-start.log
      register: gitlab_reconfigure
      retries: 2
      delay: 30
      until: gitlab_reconfigure.rc == 0

    - name: 等待GitLab所有组件启动
      shell: |
        for i in {1..60}; do
          status=$(gitlab-ctl status | grep -c "^run:" || true)
          total=$(gitlab-ctl status | wc -l)
          echo "GitLab组件状态: $status/$total"
          if [ "$status" -eq "$total" ]; then
            echo "所有组件已启动"
            exit 0
          fi
          sleep 5
        done
        echo "超时：部分组件未启动"
        gitlab-ctl status
        exit 1
      register: gitlab_components_wait

    - name: 显示GitLab组件状态
      command: gitlab-ctl status
      register: gitlab_status_detail
      changed_when: false

    - name: 输出GitLab组件状态
      debug:
        msg: "{{ gitlab_status_detail.stdout_lines }}"

    - name: 检查GitLab Puma进程
      shell: ps aux | grep puma | grep -v grep
      register: puma_process
      failed_when: false
      changed_when: false

    - name: 显示Puma进程状态
      debug:
        msg: "{{ puma_process.stdout_lines if puma_process.rc == 0 else 'Puma进程未运行！' }}"
```

### 中期优化

#### 优化1: 创建统一的SELinux处理模块

**新文件：`playbooks/00-selinux-check.yml`**：
```yaml
---
# SELinux检查和处理（所有playbook的前置条件）
- name: SELinux状态检查和处理
  hosts: all
  become: yes
  gather_facts: yes
  tasks:
    - name: 检查SELinux当前状态
      command: getenforce
      register: selinux_current
      changed_when: false

    - name: 检查SELinux配置文件
      slurp:
        src: /etc/selinux/config
      register: selinux_config_content

    - name: 解析SELinux配置
      set_fact:
        selinux_config: "{{ selinux_config_content.content | b64decode }}"

    - name: 显示SELinux状态
      debug:
        msg:
          - "当前状态: {{ selinux_current.stdout }}"
          - "配置文件: {{ selinux_config | regex_search('SELINUX=\\w+') }}"

    - name: 如果SELinux是Enforcing，临时设置为Permissive
      command: setenforce 0
      when: selinux_current.stdout == "Enforcing"
      register: selinux_temp_disable

    - name: 永久禁用SELinux（修改配置文件）
      lineinfile:
        path: /etc/selinux/config
        regexp: '^SELINUX='
        line: 'SELINUX=disabled'
      when: selinux_current.stdout != "Disabled"
      register: selinux_config_change

    - name: 提示重启（如果需要）
      debug:
        msg: |
          ⚠️  SELinux配置已更改，建议在部署完成后重启系统以完全禁用SELinux。
          当前已临时设置为Permissive模式，不会阻止服务运行。
      when: selinux_config_change is changed

    - name: 验证SELinux不会阻止服务
      assert:
        that:
          - selinux_current.stdout == "Disabled" or selinux_current.stdout == "Permissive" or selinux_temp_disable is changed
        fail_msg: "SELinux仍为Enforcing状态且无法临时禁用！"
        success_msg: "SELinux检查通过"
```

#### 优化2: 资源检查和预警

**新文件：`playbooks/00-resource-check.yml`**：
```yaml
---
# 系统资源检查（部署前验证）
- name: 系统资源预检查
  hosts: all
  become: yes
  gather_facts: yes
  tasks:
    - name: 检查系统内存
      set_fact:
        total_memory_mb: "{{ (ansible_memtotal_mb | int) }}"
        required_memory_mb: 8192  # 单节点最少8GB

    - name: 检查磁盘空间
      set_fact:
        root_disk_free_gb: "{{ (ansible_mounts | selectattr('mount', 'equalto', '/') | map(attribute='size_available') | first / 1024 / 1024 / 1024) | int }}"
        required_disk_gb: 50

    - name: 检查CPU核心数
      set_fact:
        total_cpu_cores: "{{ ansible_processor_vcpus }}"
        required_cpu_cores: 4

    - name: 显示资源信息
      debug:
        msg:
          - "========== 系统资源检查 =========="
          - "CPU: {{ total_cpu_cores }}核 (需要: {{ required_cpu_cores }}核)"
          - "内存: {{ total_memory_mb }}MB (需要: {{ required_memory_mb }}MB)"
          - "磁盘: {{ root_disk_free_gb }}GB (需要: {{ required_disk_gb }}GB)"
          - "=================================="

    - name: 资源充足性检查
      assert:
        that:
          - total_cpu_cores | int >= required_cpu_cores | int
          - total_memory_mb | int >= required_memory_mb | int
          - root_disk_free_gb | int >= required_disk_gb | int
        fail_msg: |
          ❌ 系统资源不足！
          
          当前资源：
            CPU: {{ total_cpu_cores }}核 / 需要: {{ required_cpu_cores }}核
            内存: {{ total_memory_mb }}MB / 需要: {{ required_memory_mb }}MB
            磁盘: {{ root_disk_free_gb }}GB / 需要: {{ required_disk_gb }}GB
          
          建议：
          1. 增加虚拟机资源配置
          2. 或禁用部分服务（如Harbor、监控等）
          3. 或使用多节点部署
        success_msg: "✓ 系统资源检查通过"

    - name: 资源警告（资源紧张但可运行）
      debug:
        msg: |
          ⚠️  警告：系统资源接近最低要求！
          
          建议增加以下资源：
          {% if total_memory_mb | int < 12288 %}
          - 内存：当前{{ total_memory_mb }}MB，建议至少12GB
          {% endif %}
          {% if root_disk_free_gb | int < 100 %}
          - 磁盘：当前{{ root_disk_free_gb }}GB，建议至少100GB
          {% endif %}
          {% if total_cpu_cores | int < 8 %}
          - CPU：当前{{ total_cpu_cores }}核，建议至少8核
          {% endif %}
      when: >
        (total_cpu_cores | int < 8) or
        (total_memory_mb | int < 12288) or
        (root_disk_free_gb | int < 100)
```

#### 优化3: 统一的健康检查脚本

**新文件：`scripts/comprehensive-health-check.sh`**：
```bash
#!/bin/bash
# 全面健康检查脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

check() {
    local name=$1
    local command=$2
    local expected=$3
    
    echo -n "检查 $name... "
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        ERRORS=$((ERRORS+1))
        return 1
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}全面系统健康检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. SELinux
echo -e "${BLUE}[1/12] SELinux状态${NC}"
SELINUX_STATUS=$(getenforce)
if [ "$SELINUX_STATUS" = "Disabled" ] || [ "$SELINUX_STATUS" = "Permissive" ]; then
    echo -e "  ${GREEN}✓${NC} SELinux: $SELINUX_STATUS"
else
    echo -e "  ${RED}✗${NC} SELinux: $SELINUX_STATUS (应该是Disabled或Permissive)"
    ERRORS=$((ERRORS+1))
fi

# 2. 系统资源
echo -e "${BLUE}[2/12] 系统资源${NC}"
FREE_MEM=$(free -m | awk 'NR==2{print $7}')
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
CPU_CORES=$(nproc)

echo "  内存: ${FREE_MEM}MB 可用 / ${TOTAL_MEM}MB 总计"
echo "  磁盘: ${DISK_FREE} 可用"
echo "  CPU: ${CPU_CORES} 核"

if [ "$FREE_MEM" -lt 2048 ]; then
    echo -e "  ${YELLOW}⚠${NC} 可用内存不足2GB"
    WARNINGS=$((WARNINGS+1))
fi

# 3-12. 服务检查...
# (完整脚本省略，包含所有服务的详细检查)

echo ""
echo -e "${BLUE}========================================${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 有 $WARNINGS 个警告${NC}"
    exit 0
else
    echo -e "${RED}✗ 发现 $ERRORS 个错误和 $WARNINGS 个警告${NC}"
    exit 1
fi
```

### 长期改进

#### 改进1: 实现幂等性
- 所有playbook应该支持重复运行
- 添加状态检查，避免重复操作
- 使用Ansible的模块特性（大部分已实现）

#### 改进2: 添加回滚机制
- 每个关键步骤前创建快照或备份
- 失败时自动回滚到上一个稳定状态

#### 改进3: 分离部署和验证
- 部署脚本专注于安装和配置
- 验证脚本独立运行，可重复执行
- 添加烟雾测试（smoke tests）

#### 改进4: 监控和告警
- 添加Prometheus规则监控关键指标
- 配置Alertmanager告警通知
- 添加日志聚合（ELK或Loki）

---

## 📝 立即执行的修复步骤

### 步骤1: 在虚拟机上检查SELinux（紧急）

```bash
ssh root@192.168.76.141

# 检查SELinux状态
getenforce

# 如果是Enforcing，立即临时禁用
sudo setenforce 0

# 永久禁用
sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config

# 验证
getenforce  # 应该返回Permissive
cat /etc/selinux/config | grep ^SELINUX=

# 重启GitLab
gitlab-ctl restart

# 等待5分钟
sleep 300

# 测试
curl -I http://127.0.0.1:8081/-/readiness
```

### 步骤2: 验证数据库连接

```bash
# 测试PostgreSQL
systemctl status postgresql
sudo -u postgres psql -c "\l" | grep gitlabhq

# 测试GitLab数据库连接（如果失败，改回trust）
sudo -u postgres psql -h 127.0.0.1 -U gitlab -d gitlabhq_production -W
# 密码: gitlab123

# 如果连接失败，临时改回trust
sudo sed -i 's/md5/trust/g' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
gitlab-ctl restart
```

### 步骤3: 检查服务状态

```bash
# 检查所有关键服务
systemctl status postgresql redis nginx gitlab-runsvdir.service

# 检查GitLab组件
gitlab-ctl status

# 查看GitLab日志
gitlab-ctl tail puma
gitlab-ctl tail nginx

# 查看错误
tail -100 /var/log/gitlab/gitlab-rails/production.log | grep -i error
```

### 步骤4: 运行诊断脚本

```bash
cd /root/cloud-native-devops-platform
./scripts/gitlab-diagnosis.sh
./quick-fix-gitlab.sh
```

### 步骤5: 重新运行验证

```bash
# 等待5分钟确保所有服务稳定
sleep 300

# 运行验证
ansible-playbook -i inventory/single-node.yml playbooks/07-verification.yml
```

---

## 📊 修复优先级矩阵

| 问题 | 严重性 | 紧急度 | 优先级 | 修复时间 |
|------|--------|--------|--------|----------|
| SELinux Enforcing | 高 | 高 | P0 | 5分钟 |
| 数据库连接失败 | 高 | 高 | P0 | 10分钟 |
| 服务启动顺序 | 中 | 高 | P1 | 30分钟 |
| 资源不足 | 中 | 中 | P2 | 1小时 |
| 缺少验证 | 低 | 中 | P3 | 2小时 |
| 配置不一致 | 低 | 低 | P4 | 已修复 |

---

## 🎯 预期结果

执行完所有修复后，应该：
- ✅ SELinux处于Disabled或Permissive状态
- ✅ PostgreSQL和Redis正常运行且可连接
- ✅ GitLab所有组件状态为"run"
- ✅ `curl http://127.0.0.1:8081/-/readiness` 返回200
- ✅ `curl http://192.168.76.141/` 返回GitLab登录页面
- ✅ `curl http://192.168.76.141/api/v4/version` 返回200或401

---

## 📞 如果问题仍未解决

请收集以下信息：
```bash
# 1. SELinux状态
getenforce
cat /etc/selinux/config

# 2. 服务状态
gitlab-ctl status
systemctl status postgresql redis nginx

# 3. 日志（最重要）
tail -200 /var/log/gitlab/gitlab-rails/production.log > ~/gitlab-rails.log
tail -200 /var/log/gitlab/puma/puma_stdout.log > ~/gitlab-puma.log
journalctl -u gitlab-runsvdir -n 200 > ~/gitlab-service.log
tail -100 /var/log/nginx/error.log > ~/nginx-error.log

# 4. 资源状态
free -h > ~/memory.txt
df -h > ~/disk.txt
ps aux | grep -E 'puma|postgres|redis' > ~/processes.txt

# 打包所有日志
tar -czf ~/gitlab-debug-$(date +%Y%m%d-%H%M%S).tar.gz ~/*.log ~/*.txt
```

然后将 `gitlab-debug-*.tar.gz` 文件发给我分析。

---

**文档版本**: 1.0  
**最后更新**: 2025-10-28  
**作者**: AI DevOps Assistant

