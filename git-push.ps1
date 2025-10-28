# Simple Git Push Script
# Usage: .\git-push.ps1

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Blue
Write-Host "Push to GitHub" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue
Write-Host ""

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Git is not installed" -ForegroundColor Red
    exit 1
}

# Initialize repo if needed
if (-not (Test-Path ".git")) {
    Write-Host "[1/5] Initializing Git repository..." -ForegroundColor Green
    git init
    git branch -M main
} else {
    Write-Host "[1/5] Git repository exists" -ForegroundColor Green
}

# Add remote
Write-Host "[2/5] Setting remote..." -ForegroundColor Green
$remotes = git remote
if ($remotes -notcontains "origin") {
    git remote add origin https://github.com/xueyy-999/demo-devops-app.git
} else {
    git remote set-url origin https://github.com/xueyy-999/demo-devops-app.git
}

# Add files
Write-Host "[3/5] Adding files..." -ForegroundColor Green
git add .

# Commit
Write-Host "[4/5] Committing..." -ForegroundColor Green
git commit -m "feat: Complete cloud-native DevOps platform"

# Push
Write-Host "[5/5] Pushing to GitHub..." -ForegroundColor Green
Write-Host ""
Write-Host "You may need to enter your GitHub credentials:" -ForegroundColor Yellow
Write-Host "Username: xueyy-999" -ForegroundColor Cyan
Write-Host "Password: Use Personal Access Token (PAT)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Get PAT at: https://github.com/settings/tokens" -ForegroundColor White
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! Project pushed to GitHub" -ForegroundColor Green
    Write-Host "View at: https://github.com/xueyy-999/demo-devops-app" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "FAILED. Try manual push:" -ForegroundColor Red
    Write-Host "git push -u origin main" -ForegroundColor White
}

