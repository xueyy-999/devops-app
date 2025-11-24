# Cloud Native DevOps Platform - Quick Start Script
# For starting the platform quickly using Docker Compose on Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cloud Native DevOps Platform - Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
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
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if docker-compose is available
Write-Host "[Check] Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker compose version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose is not available"
    }
    Write-Host "[OK] Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "[Error] Docker Compose is not available" -ForegroundColor Red
    Write-Host "Please update Docker Desktop to the latest version" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Select Startup Mode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Full Start (All Services)" -ForegroundColor White
Write-Host "   - GitLab, Jenkins, Registry" -ForegroundColor Gray
Write-Host "   - Prometheus, Grafana" -ForegroundColor Gray
Write-Host "   - PostgreSQL, Redis" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Lightweight Start (Monitoring Only)" -ForegroundColor White
Write-Host "   - Prometheus, Grafana" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Stop All Services" -ForegroundColor White
Write-Host ""
Write-Host "4. Check Service Status" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Please select (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "[Start] Starting full platform..." -ForegroundColor Green
        Write-Host ""
        Write-Host "[Warn] Note: GitLab may take 5-10 minutes to be fully ready on first start" -ForegroundColor Yellow
        Write-Host ""
        
        docker compose up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Platform started successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "[Info] Service Access URLs:" -ForegroundColor Cyan
            Write-Host "   GitLab:     http://localhost" -ForegroundColor White
            Write-Host "   Jenkins:    http://localhost:8080" -ForegroundColor White
            Write-Host "   Registry:   http://localhost:5000" -ForegroundColor White
            Write-Host "   Prometheus: http://localhost:9090" -ForegroundColor White
            Write-Host "   Grafana:    http://localhost:3000" -ForegroundColor White
            Write-Host ""
            Write-Host "[Key] Default Credentials:" -ForegroundColor Cyan
            Write-Host "   GitLab:  root / gitlab123456" -ForegroundColor White
            Write-Host "   Grafana: admin / admin123" -ForegroundColor White
            Write-Host "   Registry: No auth required (local dev env)" -ForegroundColor White
            Write-Host ""
            Write-Host "[Tip] Tip: Use 'docker compose logs -f' to view logs" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "[Error] Startup failed, please check error messages" -ForegroundColor Red
        }
    }
    "2" {
        Write-Host ""
        Write-Host "[Start] Starting monitoring services..." -ForegroundColor Green
        Write-Host ""
        
        docker compose up -d prometheus grafana
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Monitoring services started successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "[Info] Service Access URLs:" -ForegroundColor Cyan
            Write-Host "   Prometheus: http://localhost:9090" -ForegroundColor White
            Write-Host "   Grafana:    http://localhost:3000" -ForegroundColor White
            Write-Host ""
            Write-Host "[Key] Grafana Account: admin / admin123" -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "[Error] Startup failed, please check error messages" -ForegroundColor Red
        }
    }
    "3" {
        Write-Host ""
        Write-Host "[Stop] Stopping all services..." -ForegroundColor Yellow
        Write-Host ""
        
        docker compose down
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] All services stopped" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[Error] Stop failed, please check error messages" -ForegroundColor Red
        }
    }
    "4" {
        Write-Host ""
        Write-Host "[Status] Service Status:" -ForegroundColor Cyan
        Write-Host ""
        
        docker compose ps
    }
    default {
        Write-Host ""
        Write-Host "[Error] Invalid selection" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
