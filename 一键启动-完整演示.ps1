# Cloud Native DevOps Platform - One-Click Start Full Demo
# Includes Platform Services + Demo App

param(
    [switch]$SkipVerify = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cloud Native DevOps Platform - Full Demo Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "[Check] Checking Docker environment..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
    Write-Host "[OK] Docker is running (Version: $dockerVersion)" -ForegroundColor Green
} catch {
    Write-Host "[Error] Docker is not running or not installed" -ForegroundColor Red
    Write-Host "Please start Docker Desktop first" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Startup Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Start Platform Services
Write-Host "[Step] Step 1/3: Starting Platform Services..." -ForegroundColor Green
Write-Host "   (Prometheus, Grafana, GitLab, Jenkins, Registry, PostgreSQL, Redis)" -ForegroundColor Gray
Write-Host ""

docker compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Platform services started successfully" -ForegroundColor Green
} else {
    Write-Host "[Error] Failed to start platform services" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[Wait] Waiting for services initialization (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 2: Start Demo App
Write-Host ""
Write-Host "[Step] Step 2/3: Starting Demo App..." -ForegroundColor Green
Write-Host "   (Frontend, Backend, Demo-PostgreSQL, Demo-Redis)" -ForegroundColor Gray
Write-Host ""

Push-Location demo-app
docker-compose up -d
$demoResult = $LASTEXITCODE
Pop-Location

if ($demoResult -eq 0) {
    Write-Host "[OK] Demo app started successfully" -ForegroundColor Green
} else {
    Write-Host "[Error] Failed to start demo app" -ForegroundColor Red
}

Write-Host ""
Write-Host "[Wait] Waiting for app initialization (20 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Step 3: Verify Services
if (-not $SkipVerify) {
    Write-Host ""
    Write-Host "[Check] Step 3/3: Verifying service status..." -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path ".\scripts\verify-platform.ps1") {
        & .\scripts\verify-platform.ps1
    } else {
        Write-Host "[Warn] Verification script .\scripts\verify-platform.ps1 not found, skipping verification." -ForegroundColor Yellow
    }
}

# Show Access Info
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  [OK] Startup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Info] Platform Service Access URLs:" -ForegroundColor Green
Write-Host ""
Write-Host "  Monitoring System:" -ForegroundColor Yellow
Write-Host "    Prometheus:  http://localhost:9090" -ForegroundColor White
Write-Host "    Grafana:     http://localhost:3000  (admin/admin123)" -ForegroundColor White
Write-Host ""
Write-Host "  CI/CD System:" -ForegroundColor Yellow
Write-Host "    GitLab:      http://localhost  (root/gitlab123456)" -ForegroundColor White
Write-Host "    Jenkins:     http://localhost:8080" -ForegroundColor White
Write-Host "    Registry:    http://localhost:5000" -ForegroundColor White
Write-Host ""
Write-Host "  Databases:" -ForegroundColor Yellow
Write-Host "    PostgreSQL:  localhost:5432" -ForegroundColor White
Write-Host "    Redis:       localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "  Demo App:" -ForegroundColor Yellow
Write-Host "    Frontend:    http://localhost:8888  * Main Demo" -ForegroundColor White
Write-Host "    Backend API: http://localhost:5001" -ForegroundColor White
Write-Host ""

Write-Host "[Tip] Tips:" -ForegroundColor Cyan
Write-Host "  - GitLab may take 5-10 minutes to be fully ready on first start" -ForegroundColor Gray
Write-Host "  - Use 'docker compose logs -f' to view platform logs" -ForegroundColor Gray
Write-Host "  - Use 'docker compose -f demo-app/docker-compose.yml logs -f' to view app logs" -ForegroundColor Gray
Write-Host "  - View Demo Guide: 演示指南-答辩专用.md" -ForegroundColor Gray
Write-Host ""

Write-Host "[Action] Quick Verify:" -ForegroundColor Cyan
Write-Host "  .\scripts\verify-platform.ps1" -ForegroundColor White
Write-Host ""

Write-Host "[Stop] Stop All Services:" -ForegroundColor Cyan
Write-Host "  docker compose down" -ForegroundColor White
Write-Host "  docker compose -f demo-app/docker-compose.yml down" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ask to open browser
$openBrowser = Read-Host "Open browser to access demo app? (Y/N)"
if ($openBrowser -eq "Y" -or $openBrowser -eq "y") {
    Start-Process "http://localhost:8888"
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:9090"
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:3000"
}

Write-Host "[OK] Done! Good luck with the demo!" -ForegroundColor Green
Write-Host ""
