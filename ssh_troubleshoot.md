# SSH Connection Troubleshooting Guide

## 目标
帮助定位并解决 `ssh root@<IP>` 连接后立即被关闭的问题。

## 步骤
1. **检查 SSH 服务状态**
   ```bash
   systemctl status sshd
   ```
   确认服务为 `active (running)`，并记录输出。

2. **查看系统日志**
   ```bash
   journalctl -u sshd -n 50 --no-pager
   ```
   或者在 Ubuntu/Debian 系统上：
   ```bash
   tail -n 50 /var/log/auth.log | grep sshd
   ```
   将最近的几行复制粘贴给我。

3. **以调试模式运行 SSH 服务器**（需要在控制台执行）
   ```bash
   # 停止当前服务
   sudo systemctl stop sshd
   # 以调试模式前台运行（会输出详细信息）
   sudo /usr/sbin/sshd -d -D
   ```
   保持此窗口打开，然后在 Windows 上再次尝试连接：
   ```powershell
   ssh root@192.168.17.113
   ```
   将调试模式窗口的输出截图或粘贴给我。

4. **检查 root 用户的登录 Shell**
   ```bash
   grep '^root:' /etc/passwd
   ```
   确认 Shell 为 `/bin/bash`（或其他有效的 shell）。如果不是，请修改：
   ```bash
   sudo usermod -s /bin/bash root
   ```

5. **检查 root 用户的 .bashrc / .profile**
   ```bash
   cat /root/.bashrc
   cat /root/.profile
   ```
   确认没有 `exit`、`logout` 或导致会话立即退出的命令。

6. **创建普通测试用户**（排除 root 配置问题）
   ```bash
   sudo adduser testuser
   # 按提示设置密码
   sudo usermod -aG sudo testuser   # 如需 sudo 权限
   ```
   然后尝试：
   ```powershell
   ssh testuser@192.168.17.113
   ```
   看是否仍然被关闭。

## 常见原因
- **缺失的 `/run/sshd` 目录**（已在之前步骤中创建）
- **`/etc/ssh/sshd_config` 中的 `AllowUsers`、`DenyUsers`、`PermitRootLogin` 配置错误**
- **root 用户的登录 Shell 或 `.bashrc` 中的 `exit`**
- **防火墙或 TCP Wrappers（`/etc/hosts.allow` / `hosts.deny`）阻止**

## 下一步
请按照上述步骤执行，并把 **系统日志**、**调试模式输出** 或 **错误信息** 发给我，我会帮助进一步定位根本原因。
