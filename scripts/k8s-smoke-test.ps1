param(
  [string]$Namespace = "",
  [string]$OutputJson = "docs/testing/k8s_smoke_test.json"
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "$Name 未找到，请先安装并加入 PATH" }
}

function Run([string]$Label, [string]$CommandLine) {
  $start = Get-Date
  $ok = $true
  $output = ""
  try {
    $output = Invoke-Expression $CommandLine 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { $ok = $false }
  } catch {
    $ok = $false
    $output = $_.Exception.Message
  }
  $end = Get-Date
  return [PSCustomObject]@{
    label = $Label
    ok = $ok
    started_at = $start.ToString("s")
    finished_at = $end.ToString("s")
    command = $CommandLine
    output = $output.TrimEnd()
  }
}

Require-Command kubectl

$nsArg = ""
if ($Namespace) { $nsArg = "-n $Namespace" }

$items = @()
$items += Run "nodes" "kubectl get nodes -o wide"
$items += Run "pods" "kubectl get pods -A -o wide"
$items += Run "deploy/svc/ing" "kubectl get deploy,svc,ing $nsArg -o wide"
$items += Run "hpa" "kubectl get hpa $nsArg -o wide"
$items += Run "events" "kubectl get events $nsArg --sort-by=.metadata.creationTimestamp | Select-Object -Last 50"

$summary = [PSCustomObject]@{
  generated_at = (Get-Date).ToString("s")
  namespace = $Namespace
  results = $items
  ok = -not ($items | Where-Object { -not $_.ok } | Select-Object -First 1)
}

$dir = Split-Path -Parent $OutputJson
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputJson -Encoding UTF8

Write-Host "Kubernetes 冒烟测试完成：$OutputJson"
if (-not $summary.ok) { exit 1 }

