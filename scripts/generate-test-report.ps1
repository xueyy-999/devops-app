# 生成完整的测试报告
# 包含所有组件的状态和测试结果

param(
    [string]$OutputFile = "测试报告.md"
)

$ErrorActionPreference = "Continue"

# 初始化报告
$report = @"
# 云原生DevOps平台 - 测试报告

**生成时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

---

## 📋 执行摘要

"@

# 计数器
$totalTests = 0
$passedTests = 0
$failedTests = 0

# 测试结果数组
$results = @()

# 辅助函数
function Test-Service {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Category
    )
    
    $script:totalTests++
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $status = "✅ 通过"
        $script:passedTests++
        $details = "HTTP $($response.StatusCode)"
    } catch {
        $status = "❌ 失败"
        $script:failedTests++
        $details = $_.Exception.Message
    }
    
    $script:results += [PSCustomObject]@{
        Category = $Category
        Name = $Name
        Status = $status
        Details = $details
    }
}

function Test-Container {
    param(
        [string]$Name,
        [string]$Category
    )
    
    $script:totalTests++
    
    try {
        $container = docker ps --filter "name=^${Name}$" --format "{{.Names}}" 2>$null
        
        if ($container -eq $Name) {
            $state = docker inspect --format='{{.State.Status}}' $Name 2>$null
            
            if ($state -eq "running") {
                $status = "✅ 通过"
                $script:passedTests++
                $details = "运行中"
            } else {
                $status = "❌ 失败"
                $script:failedTests++
                $details = "状态: $state"
            }
        } else {
            $status = "❌ 失败"
            $script:failedTests++
            $details = "容器未运行"
        }
    } catch {
        $status = "❌ 失败"
        $script:failedTests++
        $details = $_.Exception.Message
    }
    
    $script:results += [PSCustomObject]@{
        Category = $Category
        Name = $Name
        Status = $status
        Details = $details
    }
}

Write-Host "🔍 开始生成测试报告..." -ForegroundColor Cyan
Write-Host ""

# 1. 测试Docker环境
Write-Host "测试Docker环境..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    $results += [PSCustomObject]@{
        Category = "环境检查"
        Name = "Docker"
        Status = "✅ 通过"
        Details = "版本: $dockerVersion"
    }
    $totalTests++
    $passedTests++
} catch {
    $results += [PSCustomObject]@{
        Category = "环境检查"
        Name = "Docker"
        Status = "❌ 失败"
        Details = "Docker未运行"
    }
    $totalTests++
    $failedTests++
}

# 2. 测试容器状态
Write-Host "测试容器状态..." -ForegroundColor Yellow
Test-Container "prometheus" "容器状态"
Test-Container "grafana" "容器状态"
Test-Container "gitlab" "容器状态"
Test-Container "jenkins" "容器状态"
Test-Container "registry" "容器状态"
Test-Container "postgres" "容器状态"
Test-Container "redis" "容器状态"

# 3. 测试服务可访问性
Write-Host "测试服务可访问性..." -ForegroundColor Yellow
Test-Service "Prometheus" "http://localhost:9090/-/healthy" "监控服务"
Test-Service "Grafana" "http://localhost:3000/api/health" "监控服务"
Test-Service "GitLab" "http://localhost/-/health" "CI/CD服务"
Test-Service "Jenkins" "http://localhost:8080/login" "CI/CD服务"
Test-Service "Registry" "http://localhost:5000/v2/" "CI/CD服务"
Test-Service "Demo Frontend" "http://localhost:8888" "示例应用"
Test-Service "Demo Backend" "http://localhost:5001/health" "示例应用"

# 4. 测试数据库
Write-Host "测试数据库..." -ForegroundColor Yellow
try {
    $pgResult = docker exec postgres pg_isready -U gitlab 2>$null
    if ($LASTEXITCODE -eq 0) {
        $results += [PSCustomObject]@{
            Category = "数据库"
            Name = "PostgreSQL"
            Status = "✅ 通过"
            Details = "连接正常"
        }
        $passedTests++
    } else {
        $results += [PSCustomObject]@{
            Category = "数据库"
            Name = "PostgreSQL"
            Status = "❌ 失败"
            Details = "连接失败"
        }
        $failedTests++
    }
    $totalTests++
} catch {
    $results += [PSCustomObject]@{
        Category = "数据库"
        Name = "PostgreSQL"
        Status = "❌ 失败"
        Details = $_.Exception.Message
    }
    $totalTests++
    $failedTests++
}

# 生成报告内容
$report += @"

| 指标 | 数值 |
|------|------|
| 总测试项 | $totalTests |
| 通过 | $passedTests ✅ |
| 失败 | $failedTests ❌ |
| 通过率 | $([math]::Round($passedTests/$totalTests*100, 2))% |

---

## 📊 详细测试结果

"@

# 按类别分组
$categories = $results | Group-Object -Property Category

foreach ($category in $categories) {
    $report += "`n### $($category.Name)`n`n"
    $report += "| 测试项 | 状态 | 详情 |`n"
    $report += "|--------|------|------|`n"
    
    foreach ($item in $category.Group) {
        $report += "| $($item.Name) | $($item.Status) | $($item.Details) |`n"
    }
}

# 添加系统信息
$report += @"

---

## 💻 系统信息

| 项目 | 信息 |
|------|------|
| 操作系统 | $([System.Environment]::OSVersion.VersionString) |
| PowerShell版本 | $($PSVersionTable.PSVersion) |
| 主机名 | $env:COMPUTERNAME |
| 用户 | $env:USERNAME |

---

## 📝 建议

"@

if ($failedTests -eq 0) {
    $report += "`n✅ **所有测试通过！** 平台运行正常，可以进行演示。`n"
} else {
    $report += "`n⚠️ **发现 $failedTests 个失败项**，建议：`n`n"
    $report += "1. 检查失败的服务日志: ``docker logs <service_name>```n"
    $report += "2. 重启失败的服务: ``docker restart <service_name>```n"
    $report += "3. 查看故障排查指南: ``IMMEDIATE_FIX_GUIDE.md```n"
}

$report += @"

---

**报告生成完成** - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

# 保存报告
$report | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "✅ 测试报告已生成: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "📊 测试摘要:" -ForegroundColor Cyan
Write-Host "   总测试项: $totalTests" -ForegroundColor White
Write-Host "   通过: $passedTests" -ForegroundColor Green
Write-Host "   失败: $failedTests" -ForegroundColor Red
Write-Host "   通过率: $([math]::Round($passedTests/$totalTests*100, 2))%" -ForegroundColor Cyan
Write-Host ""

# 打开报告
$open = Read-Host "是否打开报告? (Y/N)"
if ($open -eq "Y" -or $open -eq "y") {
    Start-Process $OutputFile
}

