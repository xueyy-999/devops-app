# 云原生DevOps平台 - 完整验证脚本 (PowerShell版本)
# 验证所有组件是否正常工作

$ErrorActionPreference = "Continue"

# 计数器
$script:TotalChecks = 0
$script:PassedChecks = 0
$script:FailedChecks = 0

# 打印函数
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
    $script:PassedChecks++
    $script:TotalChecks++
}

function Print-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
    $script:FailedChecks++
    $script:TotalChecks++
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# 检查服务是否可访问
function Check-Service {
    param(
        [string]$Name,
        [string]$Url,
        [int]$ExpectedCode = 200
    )
    
    Print-Info "检查 $Name : $Url"
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq $ExpectedCode -or $statusCode -eq 200 -or $statusCode -eq 302) {
            Print-Success "$Name 可访问 (HTTP $statusCode)"
            return $true
        } else {
            Print-Error "$Name 响应异常 (HTTP $statusCode)"
            return $false
        }
    } catch {
        Print-Error "$Name 不可访问: $($_.Exception.Message)"
        return $false
    }
}

# 检查Docker容器
function Check-DockerContainer {
    param([string]$ContainerName)
    
    try {
        $container = docker ps --filter "name=^${ContainerName}$" --format "{{.Names}}" 2>$null
        
        if ($container -eq $ContainerName) {
            $status = docker inspect --format='{{.State.Status}}' $ContainerName 2>$null
            
            if ($status -eq "running") {
                Print-Success "容器 $ContainerName 正在运行"
                return $true
            } else {
                Print-Error "容器 $ContainerName 状态异常: $status"
                return $false
            }
        } else {
            Print-Error "容器 $ContainerName 未运行"
            return $false
        }
    } catch {
        Print-Error "检查容器 $ContainerName 失败: $($_.Exception.Message)"
        return $false
    }
}

# 主验证流程
function Main {
    Print-Header "云原生DevOps平台 - 系统验证"
    
    # 检查Docker是否运行
    try {
        docker version | Out-Null
        Print-Info "Docker 已运行"
    } catch {
        Print-Error "Docker 未运行或未安装"
        Write-Host ""
        Write-Host "请先启动 Docker Desktop" -ForegroundColor Yellow
        exit 1
    }
    
    # 1. 检查Docker容器
    Print-Header "1. 检查Docker容器状态"
    Check-DockerContainer "prometheus"
    Check-DockerContainer "grafana"
    Check-DockerContainer "gitlab"
    Check-DockerContainer "jenkins"
    Check-DockerContainer "registry"
    Check-DockerContainer "postgres"
    Check-DockerContainer "redis"
    
    # 2. 检查监控服务
    Print-Header "2. 检查监控服务"
    Check-Service "Prometheus" "http://localhost:9090/-/healthy"
    Check-Service "Grafana" "http://localhost:3000/api/health"
    
    # 3. 检查CI/CD服务
    Print-Header "3. 检查CI/CD服务"
    Check-Service "GitLab" "http://localhost/-/health"
    Check-Service "Jenkins" "http://localhost:8080/login"
    Check-Service "Registry" "http://localhost:5000/v2/"
    
    # 4. 检查数据库服务
    Print-Header "4. 检查数据库服务"
    try {
        $pgResult = docker exec postgres pg_isready -U gitlab 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "PostgreSQL 数据库正常"
        } else {
            Print-Error "PostgreSQL 数据库异常"
        }
    } catch {
        Print-Error "无法检查 PostgreSQL"
    }
    
    try {
        $redisResult = docker exec redis redis-cli ping 2>$null
        if ($redisResult -match "PONG") {
            Print-Success "Redis 缓存正常"
        } else {
            Print-Error "Redis 缓存异常"
        }
    } catch {
        Print-Error "无法检查 Redis"
    }
    
    # 5. 检查示例应用
    Print-Header "5. 检查示例应用"
    Check-Service "Demo Frontend" "http://localhost:8888"
    Check-Service "Demo Backend" "http://localhost:5001/health"
    
    # 6. 生成报告
    Print-Header "验证报告"
    Write-Host "总检查项: " -NoNewline
    Write-Host $script:TotalChecks -ForegroundColor Cyan
    Write-Host "通过: " -NoNewline
    Write-Host $script:PassedChecks -ForegroundColor Green
    Write-Host "失败: " -NoNewline
    Write-Host $script:FailedChecks -ForegroundColor Red
    
    Write-Host ""
    if ($script:FailedChecks -eq 0) {
        Print-Success "所有检查通过！平台运行正常 🎉"
        Write-Host ""
        Write-Host "📋 访问地址:" -ForegroundColor Cyan
        Write-Host "   Prometheus: http://localhost:9090" -ForegroundColor White
        Write-Host "   Grafana:    http://localhost:3000" -ForegroundColor White
        Write-Host "   GitLab:     http://localhost" -ForegroundColor White
        Write-Host "   Jenkins:    http://localhost:8080" -ForegroundColor White
        Write-Host "   Registry:   http://localhost:5000" -ForegroundColor White
        Write-Host "   Demo App:   http://localhost:8888" -ForegroundColor White
        exit 0
    } else {
        Print-Error "部分检查失败，请查看上述错误信息"
        exit 1
    }
}

# 运行主函数
Main

