param(
  [string]$OutputFile = "docs/testing/测试报告.md"
)

$ErrorActionPreference = "Continue"

$totalTests = 0
$passedTests = 0
$failedTests = 0
$results = @()

function Add-Result([string]$Category, [string]$Name, [string]$Status, [string]$Details) {
  $script:results += [PSCustomObject]@{
    Category = $Category
    Name = $Name
    Status = $Status
    Details = $Details
  }
}

function Test-Service([string]$Name, [string]$Url, [string]$Category) {
  $script:totalTests++
  try {
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $script:passedTests++
    Add-Result $Category $Name "✅ 通过" ("HTTP " + $resp.StatusCode)
  } catch {
    $script:failedTests++
    Add-Result $Category $Name "❌ 失败" $_.Exception.Message
  }
}

function Test-Container([string]$Name, [string]$Category) {
  $script:totalTests++
  try {
    $container = docker ps --filter "name=^${Name}$" --format "{{.Names}}" 2>$null
    if ($container -eq $Name) {
      $state = docker inspect --format='{{.State.Status}}' $Name 2>$null
      if ($state -eq "running") {
        $script:passedTests++
        Add-Result $Category $Name "✅ 通过" "运行中"
      } else {
        $script:failedTests++
        Add-Result $Category $Name "❌ 失败" ("状态: " + $state)
      }
    } else {
      $script:failedTests++
      Add-Result $Category $Name "❌ 失败" "容器未运行"
    }
  } catch {
    $script:failedTests++
    Add-Result $Category $Name "❌ 失败" $_.Exception.Message
  }
}

try {
  $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
  $totalTests++
  $passedTests++
  Add-Result "环境检查" "Docker" "✅ 通过" ("版本: " + $dockerVersion)
} catch {
  $totalTests++
  $failedTests++
  Add-Result "环境检查" "Docker" "❌ 失败" "Docker未运行"
}

Test-Container "prometheus" "容器状态"
Test-Container "grafana" "容器状态"
Test-Container "gitlab" "容器状态"
Test-Container "jenkins" "容器状态"
Test-Container "registry" "容器状态"
Test-Container "postgres" "容器状态"
Test-Container "redis" "容器状态"

Test-Service "Prometheus" "http://localhost:9090/-/healthy" "监控服务"
Test-Service "Grafana" "http://localhost:3000/api/health" "监控服务"
Test-Service "GitLab" "http://localhost/-/health" "CI/CD服务"
Test-Service "Jenkins" "http://localhost:8080/login" "CI/CD服务"
Test-Service "Registry" "http://localhost:5000/v2/" "CI/CD服务"
Test-Service "Demo Frontend" "http://localhost:8888" "示例应用"
Test-Service "Demo Backend" "http://localhost:5001/health" "示例应用"

$passRate = 0
if ($totalTests -gt 0) { $passRate = [math]::Round($passedTests / $totalTests * 100, 2) }

$report = @()
$report += "# 云原生DevOps平台 - 测试报告"
$report += ""
$report += "**生成时间**: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$report += ""
$report += "## 执行摘要"
$report += ""
$report += "| 指标 | 数值 |"
$report += "|---|---:|"
$report += "| 总测试项 | $totalTests |"
$report += "| 通过 | $passedTests |"
$report += "| 失败 | $failedTests |"
$report += "| 通过率 | $passRate% |"
$report += ""
$categories = $results | Group-Object -Property Category
foreach ($category in $categories) {
  $report += "## " + $category.Name
  $report += ""
  $report += "| 测试项 | 状态 | 详情 |"
  $report += "|---|---|---|"
  foreach ($item in $category.Group) {
    $report += "| " + $item.Name + " | " + $item.Status + " | " + $item.Details.Replace("`n", " ") + " |"
  }
  $report += ""
}

$dir = Split-Path -Parent $OutputFile
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$report -join "`n" | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "测试报告已生成：$OutputFile"
if ($failedTests -gt 0) { exit 1 }

