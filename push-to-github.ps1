# 推送项目到GitHub脚本
# 使用方法: .\push-to-github.ps1

$REPO_URL = "https://github.com/xueyy-999/demo-devops-app.git"
$BRANCH = "main"

Write-Host "========================================" -ForegroundColor Blue
Write-Host "推送项目到GitHub" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""
Write-Host "仓库地址: $REPO_URL" -ForegroundColor Cyan
Write-Host "分支: $BRANCH" -ForegroundColor Cyan
Write-Host ""

# 检查Git是否安装
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "错误: Git未安装" -ForegroundColor Red
    Write-Host "请先安装Git: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# 检查是否在项目目录
if (-not (Test-Path "ansible.cfg")) {
    Write-Host "错误: 请在项目根目录下运行此脚本" -ForegroundColor Red
    exit 1
}

# 1. 初始化Git仓库（如果还没初始化）
if (-not (Test-Path ".git")) {
    Write-Host "[1/6] 初始化Git仓库..." -ForegroundColor Green
    git init
    git branch -M $BRANCH
} else {
    Write-Host "[1/6] Git仓库已存在" -ForegroundColor Green
}

# 2. 添加远程仓库
Write-Host "[2/6] 配置远程仓库..." -ForegroundColor Green
$remotes = git remote
if ($remotes -notcontains "origin") {
    git remote add origin $REPO_URL
    Write-Host "  远程仓库已添加" -ForegroundColor Cyan
} else {
    git remote set-url origin $REPO_URL
    Write-Host "  远程仓库已更新" -ForegroundColor Cyan
}

# 3. 添加所有文件
Write-Host "[3/6] 添加文件..." -ForegroundColor Green
git add .

# 4. 显示将要提交的文件
Write-Host "[4/6] 检查变更..." -ForegroundColor Green
$status = git status --short
if ($status) {
    Write-Host "将要提交的文件:" -ForegroundColor Cyan
    Write-Host $status
    Write-Host ""
} else {
    Write-Host "  没有新的变更" -ForegroundColor Yellow
}

# 5. 提交
Write-Host "[5/6] 提交变更..." -ForegroundColor Green
$commitMsg = "feat: 完整的云原生DevOps平台自动化部署方案"

git commit -m $commitMsg

# 6. 推送到GitHub
Write-Host "[6/6] 推送到GitHub..." -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  注意: 如果这是首次推送，可能需要输入GitHub用户名和密码" -ForegroundColor Yellow
Write-Host "或者需要配置Personal Access Token (PAT)" -ForegroundColor Yellow
Write-Host ""
Write-Host "如何获取PAT:" -ForegroundColor Cyan
Write-Host "1. 访问 https://github.com/settings/tokens" -ForegroundColor White
Write-Host "2. 点击 'Generate new token (classic)'" -ForegroundColor White
Write-Host "3. 选择 'repo' 权限" -ForegroundColor White
Write-Host "4. 复制token，用作密码" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "确认推送到GitHub? (y/N)"
if ($confirm -eq "y" -or $confirm -eq "Y") {
    git push -u origin $BRANCH
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ 推送成功！" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "查看项目: $REPO_URL" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "下一步:" -ForegroundColor Yellow
        Write-Host "1. 访问GitHub仓库查看项目" -ForegroundColor White
        Write-Host "2. 编辑README.md添加更多细节" -ForegroundColor White
        Write-Host "3. 添加LICENSE文件" -ForegroundColor White
        Write-Host "4. 创建Release版本" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "✗ 推送失败" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "可能的原因:" -ForegroundColor Yellow
        Write-Host "1. 认证失败 - 需要配置GitHub凭据" -ForegroundColor White
        Write-Host "2. 网络问题 - 检查网络连接" -ForegroundColor White
        Write-Host "3. 仓库权限问题 - 确认你有写权限" -ForegroundColor White
        Write-Host ""
        Write-Host "解决方案:" -ForegroundColor Cyan
        Write-Host "方法1: 使用HTTPS + PAT" -ForegroundColor White
        Write-Host "  git remote set-url origin https://YOUR_PAT@github.com/xueyy-999/demo-devops-app.git" -ForegroundColor Gray
        Write-Host ""
        Write-Host "方法2: 使用SSH" -ForegroundColor White
        Write-Host "  git remote set-url origin git@github.com:xueyy-999/demo-devops-app.git" -ForegroundColor Gray
        Write-Host "  (需要先配置SSH密钥)" -ForegroundColor Gray
    }
} else {
    Write-Host "已取消推送" -ForegroundColor Yellow
}

