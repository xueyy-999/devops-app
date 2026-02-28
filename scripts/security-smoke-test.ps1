param(
  [string]$Namespace = "default",
  [string]$ServiceAccount = "",
  [string]$OutputJson = "docs/testing/security_smoke_test.json"
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

$asArg = ""
if ($ServiceAccount) { $asArg = "--as=system:serviceaccount:$Namespace:$ServiceAccount" }

$items = @()
$items += Run "rbac can-i get pods" "kubectl auth can-i get pods -n $Namespace $asArg"
$items += Run "rbac can-i create deployments" "kubectl auth can-i create deployments -n $Namespace $asArg"
$items += Run "rbac can-i list secrets" "kubectl auth can-i list secrets -n $Namespace $asArg"
$items += Run "networkpolicies" "kubectl get networkpolicy -n $Namespace -o wide"
$items += Run "secrets count" "kubectl get secrets -n $Namespace --no-headers | Measure-Object | Select-Object -ExpandProperty Count"

$summary = [PSCustomObject]@{
  generated_at = (Get-Date).ToString("s")
  namespace = $Namespace
  service_account = $ServiceAccount
  results = $items
  ok = -not ($items | Where-Object { -not $_.ok } | Select-Object -First 1)
}

$dir = Split-Path -Parent $OutputJson
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputJson -Encoding UTF8

Write-Host "安全冒烟测试完成：$OutputJson"
if (-not $summary.ok) { exit 1 }

