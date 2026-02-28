$ErrorActionPreference = "Stop"

Write-Host "Creating project package..." -ForegroundColor Cyan

$source = "D:\3"
$output = "D:\cloud-native-devops-platform.zip"
$temp = Join-Path $env:TEMP "devops_temp"
$tempProject = Join-Path $temp "cloud-native-devops-platform"

if (Test-Path $output) {
    Remove-Item $output -Force
}

if (Test-Path $temp) {
    Remove-Item $temp -Recurse -Force
}

New-Item -ItemType Directory -Path $tempProject -Force | Out-Null

$exclude = @('.git', '.venv', '__pycache__', '.claude', 'node_modules', '.idea', '.vscode')

Get-ChildItem -Path $source -Force | Where-Object {
    $exclude -notcontains $_.Name
} | ForEach-Object {
    Write-Host "Copying: $($_.Name)" -ForegroundColor Gray
    Copy-Item -Path $_.FullName -Destination $tempProject -Recurse -Force
}

Write-Host "Compressing..." -ForegroundColor Yellow
Compress-Archive -Path "$tempProject\*" -DestinationPath $output -Force

Remove-Item $temp -Recurse -Force

$sizeMB = [math]::Round((Get-Item $output).Length / 1MB, 2)

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "File: $output" -ForegroundColor Cyan
Write-Host "Size: $sizeMB MB" -ForegroundColor Cyan

if ($sizeMB -lt 300) {
    Write-Host "Size OK (< 300MB)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Size > 300MB!" -ForegroundColor Red
}

Start-Process explorer.exe -ArgumentList "/select,`"$output`""
