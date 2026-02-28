param(
  [string]$Inventory = "inventory/single-node.yml",
  [string]$OutputJson = "docs/testing/iac_syntax_check.json"
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

Require-Command ansible-playbook

$items = @()
$items += Run "site.yml syntax check" "ansible-playbook --syntax-check site.yml"
$items += Run "00-resource-check syntax check" "ansible-playbook --syntax-check playbooks/00-resource-check.yml"
$items += Run "00-selinux-check syntax check" "ansible-playbook --syntax-check playbooks/00-selinux-check.yml"
$items += Run "01-common-setup syntax check" "ansible-playbook --syntax-check playbooks/01-common-setup.yml"
$items += Run "02-docker-setup syntax check" "ansible-playbook --syntax-check playbooks/02-docker-setup.yml"
$items += Run "03-kubernetes-fixed syntax check" "ansible-playbook --syntax-check playbooks/03-kubernetes-fixed.yml"
$items += Run "04-monitoring-setup syntax check" "ansible-playbook --syntax-check playbooks/04-monitoring-setup.yml"
$items += Run "05-cicd-setup syntax check" "ansible-playbook --syntax-check playbooks/05-cicd-setup.yml"
$items += Run "06-application-deploy syntax check" "ansible-playbook --syntax-check playbooks/06-application-deploy.yml"
$items += Run "07-verification syntax check" "ansible-playbook --syntax-check playbooks/07-verification.yml"

$summary = [PSCustomObject]@{
  generated_at = (Get-Date).ToString("s")
  inventory = $Inventory
  results = $items
  ok = -not ($items | Where-Object { -not $_.ok } | Select-Object -First 1)
}

$dir = Split-Path -Parent $OutputJson
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputJson -Encoding UTF8

Write-Host "IaC 语法检查完成：$OutputJson"
if (-not $summary.ok) { exit 1 }

