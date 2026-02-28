param(
  [string]$RegistryUrl = "localhost:5000",
  [string]$BackendImage = "demo-backend",
  [string]$FrontendImage = "demo-frontend",
  [string]$Tag = "test",
  [switch]$SkipCompose,
  [int]$HealthWaitSeconds = 45
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) { Write-Host "===> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host "❌ $Message" -ForegroundColor Red }

function Require-Command([string]$Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "$Name 未找到，请先安装并加入 PATH" }
}

function Invoke-HttpOk([string]$Url, [int[]]$AcceptCodes = @(200, 302)) {
  try {
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
    return $AcceptCodes -contains [int]$resp.StatusCode
  } catch {
    return $false
  }
}

Require-Command docker

Write-Step "1. 检查 Docker"
docker version | Out-Null
Write-Ok "Docker 可用"

Write-Step "2. 构建镜像"
Push-Location (Join-Path $PSScriptRoot "..\demo-app") | Out-Null
try {
  Push-Location "backend" | Out-Null
  try {
    docker build -t "$RegistryUrl/$BackendImage:$Tag" .
  } finally { Pop-Location | Out-Null }
  Write-Ok "后端镜像构建成功"

  Push-Location "frontend" | Out-Null
  try {
    docker build -t "$RegistryUrl/$FrontendImage:$Tag" .
  } finally { Pop-Location | Out-Null }
  Write-Ok "前端镜像构建成功"
} finally {
  Pop-Location | Out-Null
}

Write-Step "3. 运行基础镜像检查"
if (Invoke-HttpOk "http://localhost:5000/v2/") {
  Write-Step "4. 推送镜像到 Registry"
  docker push "$RegistryUrl/$BackendImage:$Tag" | Out-Null
  docker push "$RegistryUrl/$FrontendImage:$Tag" | Out-Null
  Write-Ok "镜像推送完成"
} else {
  Write-Warn "Registry 未就绪，跳过推送（http://localhost:5000/v2/ 不可访问）"
}

if (-not $SkipCompose) {
  Write-Step "5. 启动示例应用栈（docker-compose）"
  Push-Location (Join-Path $PSScriptRoot "..\demo-app") | Out-Null
  try {
    docker-compose up -d | Out-Null
  } finally {
    Pop-Location | Out-Null
  }

  Write-Step "6. 等待健康检查"
  $deadline = (Get-Date).AddSeconds($HealthWaitSeconds)
  $backendOk = $false
  $frontendOk = $false
  while ((Get-Date) -lt $deadline) {
    if (-not $backendOk) { $backendOk = Invoke-HttpOk "http://localhost:5001/health" }
    if (-not $frontendOk) { $frontendOk = Invoke-HttpOk "http://localhost:8888/" }
    if ($backendOk -and $frontendOk) { break }
    Start-Sleep -Seconds 3
  }

  if ($backendOk) { Write-Ok "后端健康检查通过" } else { Write-Fail "后端健康检查失败（http://localhost:5001/health）" }
  if ($frontendOk) { Write-Ok "前端可访问" } else { Write-Fail "前端不可访问（http://localhost:8888/）" }

  Write-Step "7. API 功能验证（创建留言）"
  try {
    $payload = @{ author = "CI_CD_TEST"; content = "自动化测试消息" } | ConvertTo-Json
    $resp = Invoke-WebRequest -Method Post -Uri "http://localhost:5001/api/messages" -ContentType "application/json" -Body $payload -UseBasicParsing -TimeoutSec 15
    if ($resp.Content -match "消息创建成功") {
      Write-Ok "API 创建消息通过"
    } else {
      Write-Fail "API 创建消息返回异常：$($resp.Content)"
    }
  } catch {
    Write-Fail "API 创建消息失败：$($_.Exception.Message)"
  }

  Write-Step "8. 清理（可选）"
  Write-Warn "未自动清理应用栈（如需清理：cd demo-app; docker-compose down）"
}

Write-Ok "CI/CD 端到端测试脚本执行完毕"

