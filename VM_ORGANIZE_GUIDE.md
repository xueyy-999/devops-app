# 虚拟机环境整理指南

本指南说明如何在虚拟机上整理云原生 DevOps 平台项目。

## 📋 当前虚拟机状态

根据你提供的 tree 输出，虚拟机当前结构：

```
/root/cloud-native-devops-platform/
├── ansible.cfg
├── fix-kubernetes-repo.sh
├── group_vars (空目录)
├── host_vars (空目录)
├── inventory/
│   ├── 06-application-deploy (错误文件，应删除)
│   ├── hosts.yml
│   └── single-node.yml
├── playbooks/ (完整)
├── scripts/ (空目录)
├── site.yml
└── templates/ (完整)
```

## 🎯 整理目标

整理后的结构：

```
/root/cloud-native-devops-platform/
├── README.md ⭐ (新增)
├── CHANGELOG.md ⭐ (新增)
├── LICENSE ⭐ (新增)
├── .gitignore ⭐ (新增)
├── ansible.cfg
├── site.yml
├── fix-kubernetes-repo.sh
├── deploy.sh (需补充)
├── deploy-single.sh (需补充)
├── docs/ ⭐ (新增目录)
│   ├── quick-start.md
│   ├── deployment-guide.md
│   ├── single-node-deployment.md
│   ├── kubernetes-fix-guide.md
│   └── CONFIGURATION.md
├── inventory/
│   ├── hosts.yml
│   ├── single-node.yml
│   ├── hosts.yml.example ⭐ (新增)
│   └── single-node.yml.example ⭐ (新增)
├── playbooks/ (保持不变)
├── templates/ (保持不变)
└── scripts/
    ├── backup.sh (需补充)
    ├── health-check.sh (需补充)
    └── quick-verify.sh (需补充)
```

## 🚀 快速整理步骤

### 方法一: 使用自动化脚本（推荐）

#### 步骤 1: 传输整理脚本到虚拟机

**在 Windows 环境 (d:\3) 执行：**

```powershell
# 使用 scp 传输脚本到虚拟机
scp vm-organize.sh root@虚拟机IP:/root/cloud-native-devops-platform/
scp vm-create-docs.sh root@虚拟机IP:/root/cloud-native-devops-platform/
```

或者使用 WinSCP、FileZilla 等工具手动传输：
- `vm-organize.sh`
- `vm-create-docs.sh`

#### 步骤 2: 在虚拟机上执行整理

**在虚拟机上执行：**

```bash
# 切换到项目目录
cd /root/cloud-native-devops-platform

# 赋予执行权限
chmod +x vm-organize.sh vm-create-docs.sh

# 执行整理脚本
bash vm-organize.sh

# 创建文档
bash vm-create-docs.sh
```

### 方法二: 完整同步 Windows 环境

如果你想完全同步 Windows 环境的整理结果：

**在 Windows 环境执行：**

```powershell
# 使用 rsync 或 scp 同步整个项目
# 注意：这会覆盖虚拟机上的文件

# 同步文档目录
scp -r d:\3\docs root@虚拟机IP:/root/cloud-native-devops-platform/

# 同步单个文件
scp d:\3\README.md root@虚拟机IP:/root/cloud-native-devops-platform/
scp d:\3\CHANGELOG.md root@虚拟机IP:/root/cloud-native-devops-platform/
scp d:\3\LICENSE root@虚拟机IP:/root/cloud-native-devops-platform/
scp d:\3\.gitignore root@虚拟机IP:/root/cloud-native-devops-platform/

# 同步配置示例
scp d:\3\inventory\*.example root@虚拟机IP:/root/cloud-native-devops-platform/inventory/

# 同步脚本
scp d:\3\scripts\* root@虚拟机IP:/root/cloud-native-devops-platform/scripts/
```

### 方法三: 手动整理

如果无法传输文件，可以手动整理：

```bash
cd /root/cloud-native-devops-platform

# 1. 创建目录
mkdir -p docs scripts

# 2. 删除错误文件
rm -f inventory/06-application-deploy

# 3. 删除空目录
rmdir group_vars host_vars 2>/dev/null || true

# 4. 创建 .gitignore
cat > .gitignore << 'EOF'
*.retry
.vault_pass
*.log
__pycache__/
*.pyc
venv/
.vscode/
.idea/
*.swp
kubeconfig
*.key
*.pem
inventory/hosts.yml
inventory/single-node.yml
!inventory/*.example
EOF

# 5. 创建 LICENSE
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Cloud Native DevOps Platform Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# 6. 创建配置示例
cp inventory/hosts.yml inventory/hosts.yml.example
cp inventory/single-node.yml inventory/single-node.yml.example
```

## 📝 整理检查清单

整理完成后，检查以下项目：

### 必需文件
- [ ] `README.md` - 项目主文档
- [ ] `LICENSE` - 许可证文件
- [ ] `.gitignore` - Git 忽略规则
- [ ] `ansible.cfg` - Ansible 配置
- [ ] `site.yml` - 主 Playbook

### 配置文件
- [ ] `inventory/hosts.yml.example` - 多节点配置示例
- [ ] `inventory/single-node.yml.example` - 单节点配置示例
- [ ] 备份原有配置文件（如果被覆盖）

### 部署脚本
- [ ] `deploy.sh` - 主部署脚本
- [ ] `deploy-single.sh` - 单节点部署脚本
- [ ] `fix-kubernetes-repo.sh` - 仓库修复脚本

### 辅助脚本
- [ ] `scripts/backup.sh` - 备份脚本
- [ ] `scripts/health-check.sh` - 健康检查
- [ ] `scripts/quick-verify.sh` - 快速验证

### 文档目录
- [ ] `docs/quick-start.md` - 快速开始
- [ ] `docs/deployment-guide.md` - 部署指南
- [ ] `docs/single-node-deployment.md` - 单节点部署
- [ ] `docs/CONFIGURATION.md` - 配置说明

## 🔍 验证整理结果

```bash
# 查看项目结构
tree -L 2

# 验证文件权限
ls -la *.sh scripts/*.sh

# 检查配置文件
cat .gitignore
cat LICENSE

# 验证 ansible 配置
ansible --version
ansible-playbook --version
```

## ⚠️ 注意事项

### 1. 备份重要配置

整理前先备份重要配置：

```bash
# 备份 inventory 配置
cp inventory/hosts.yml inventory/hosts.yml.backup.$(date +%Y%m%d)
cp inventory/single-node.yml inventory/single-node.yml.backup.$(date +%Y%m%d)

# 备份自定义配置
tar -czf backup-$(date +%Y%m%d).tar.gz inventory/ playbooks/*.yml
```

### 2. 保护敏感信息

确保不要提交敏感信息到版本控制：

```bash
# 检查 .gitignore 是否生效
git status

# 确保以下文件被忽略：
# - inventory/hosts.yml
# - inventory/single-node.yml
# - *.key, *.pem
# - kubeconfig
```

### 3. 文件权限

确保脚本有执行权限：

```bash
chmod +x *.sh
chmod +x scripts/*.sh
chmod +x playbooks/*.sh 2>/dev/null || true
```

## 🆘 常见问题

### Q1: 无法连接到虚拟机？

**解决方案：**
```bash
# 检查虚拟机 IP
ip addr show

# 检查 SSH 服务
systemctl status sshd

# 检查防火墙
firewall-cmd --list-all
```

### Q2: 文件传输失败？

**解决方案：**
- 使用 WinSCP 或 FileZilla 等图形工具
- 检查 SSH 密钥权限
- 尝试使用密码认证

### Q3: 脚本执行失败？

**解决方案：**
```bash
# 检查文件格式（Windows 换行符问题）
dos2unix vm-organize.sh vm-create-docs.sh

# 或者手动转换
sed -i 's/\r$//' vm-organize.sh
sed -i 's/\r$//' vm-create-docs.sh
```

## 📞 获取帮助

如果遇到问题：

1. 查看脚本输出日志
2. 检查 `/var/log/messages`
3. 运行 `ansible-playbook --syntax-check site.yml`
4. 查看项目 Issues

## ✅ 整理完成后

整理完成后，你可以：

```bash
# 1. 查看新的 README
cat README.md

# 2. 检查配置示例
cat inventory/single-node.yml.example

# 3. 开始部署
./deploy-single.sh

# 4. 查看文档
ls -la docs/
```

---

**整理脚本位置**: `d:\3\vm-organize.sh`, `d:\3\vm-create-docs.sh`  
**虚拟机项目路径**: `/root/cloud-native-devops-platform`

