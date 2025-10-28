# GitLab修复文件上传脚本（Windows PowerShell）
# 使用方法: .\upload-fixes.ps1

$VM_IP = "192.168.76.141"
$VM_USER = "root"
$PROJECT_PATH = "/root/cloud-native-devops-platform"

Write-Host "========================================" -ForegroundColor Blue
Write-Host "GitLab修复文件上传脚本" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# 检查SCP是否可用
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Host "错误: SCP命令不可用" -ForegroundColor Red
    Write-Host "请安装OpenSSH客户端或使用WinSCP" -ForegroundColor Yellow
    exit 1
}

# 确认虚拟机地址
Write-Host "目标虚拟机: $VM_USER@$VM_IP" -ForegroundColor Cyan
Write-Host "目标路径: $PROJECT_PATH" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "确认上传? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "开始上传文件..." -ForegroundColor Green

$files = @(
    @{Local="inventory\single-node.yml"; Remote="inventory/"},
    @{Local="playbooks\07-verification.yml"; Remote="playbooks/"},
    @{Local="scripts\gitlab-diagnosis.sh"; Remote="scripts/"},
    @{Local="quick-fix-gitlab.sh"; Remote=""},
    @{Local="GITLAB_TROUBLESHOOTING.md"; Remote=""},
    @{Local="GITLAB_FIX_SUMMARY.md"; Remote=""}
)

$success = 0
$failed = 0

foreach ($file in $files) {
    $localPath = $file.Local
    $remotePath = "${VM_USER}@${VM_IP}:${PROJECT_PATH}/$($file.Remote)"
    
    Write-Host "[上传] $localPath" -ForegroundColor Cyan
    
    try {
        scp $localPath $remotePath 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ 成功" -ForegroundColor Green
            $success++
        } else {
            Write-Host "  ✗ 失败" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  ✗ 异常: $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "上传完成: 成功 $success, 失败 $failed" -ForegroundColor $(if ($failed -eq 0) {"Green"} else {"Yellow"})
Write-Host "========================================" -ForegroundColor Blue

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "下一步操作：" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. SSH连接到虚拟机：" -ForegroundColor Cyan
    Write-Host "   ssh ${VM_USER}@${VM_IP}" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 进入项目目录：" -ForegroundColor Cyan
    Write-Host "   cd $PROJECT_PATH" -ForegroundColor White
    Write-Host ""
    Write-Host "3. 运行快速修复脚本：" -ForegroundColor Cyan
    Write-Host "   chmod +x quick-fix-gitlab.sh scripts/gitlab-diagnosis.sh" -ForegroundColor White
    Write-Host "   ./quick-fix-gitlab.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "4. 如果需要详细诊断：" -ForegroundColor Cyan
    Write-Host "   ./scripts/gitlab-diagnosis.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "5. 查看修复总结：" -ForegroundColor Cyan
    Write-Host "   cat GITLAB_FIX_SUMMARY.md" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "部分文件上传失败，请检查：" -ForegroundColor Yellow
    Write-Host "1. 虚拟机是否可达" -ForegroundColor White
    Write-Host "2. SSH密钥是否配置正确" -ForegroundColor White
    Write-Host "3. 目标路径是否存在" -ForegroundColor White
}


