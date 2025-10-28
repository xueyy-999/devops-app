#!/bin/bash
# GitLab修复文件上传脚本（Linux/Mac）
# 使用方法: ./upload-fixes.sh

VM_IP="192.168.76.141"
VM_USER="root"
PROJECT_PATH="/root/cloud-native-devops-platform"

echo "========================================"
echo "GitLab修复文件上传脚本"
echo "========================================"
echo ""

# 检查SCP是否可用
if ! command -v scp &> /dev/null; then
    echo "错误: SCP命令不可用"
    echo "请安装OpenSSH客户端"
    exit 1
fi

# 确认虚拟机地址
echo "目标虚拟机: $VM_USER@$VM_IP"
echo "目标路径: $PROJECT_PATH"
echo ""

read -p "确认上传? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "开始上传文件..."

success=0
failed=0

# 上传文件
upload_file() {
    local_path=$1
    remote_dir=$2
    
    echo "[上传] $local_path"
    
    if scp "$local_path" "${VM_USER}@${VM_IP}:${PROJECT_PATH}/${remote_dir}" 2>/dev/null; then
        echo "  ✓ 成功"
        success=$((success + 1))
    else
        echo "  ✗ 失败"
        failed=$((failed + 1))
    fi
}

# 上传所有文件
upload_file "inventory/single-node.yml" "inventory/"
upload_file "playbooks/07-verification.yml" "playbooks/"
upload_file "scripts/gitlab-diagnosis.sh" "scripts/"
upload_file "quick-fix-gitlab.sh" ""
upload_file "GITLAB_TROUBLESHOOTING.md" ""
upload_file "GITLAB_FIX_SUMMARY.md" ""

echo ""
echo "========================================"
echo "上传完成: 成功 $success, 失败 $failed"
echo "========================================"

if [ $failed -eq 0 ]; then
    echo ""
    echo "下一步操作："
    echo ""
    echo "1. SSH连接到虚拟机："
    echo "   ssh ${VM_USER}@${VM_IP}"
    echo ""
    echo "2. 进入项目目录："
    echo "   cd $PROJECT_PATH"
    echo ""
    echo "3. 运行快速修复脚本："
    echo "   chmod +x quick-fix-gitlab.sh scripts/gitlab-diagnosis.sh"
    echo "   ./quick-fix-gitlab.sh"
    echo ""
    echo "4. 如果需要详细诊断："
    echo "   ./scripts/gitlab-diagnosis.sh"
    echo ""
    echo "5. 查看修复总结："
    echo "   cat GITLAB_FIX_SUMMARY.md"
    echo ""
else
    echo ""
    echo "部分文件上传失败，请检查："
    echo "1. 虚拟机是否可达"
    echo "2. SSH密钥是否配置正确"
    echo "3. 目标路径是否存在"
fi


