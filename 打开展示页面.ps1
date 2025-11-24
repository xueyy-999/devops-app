# Cloud Native DevOps Platform - Quick Showcase Script
# For quickly opening the showcase page on Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cloud Native DevOps Platform - Service Showcase" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if showcase file exists
$showcaseFile = "web\index.html"
if (-not (Test-Path $showcaseFile)) {
    Write-Host "[Error] Showcase file not found: $showcaseFile" -ForegroundColor Red
    Write-Host "Please ensure the file exists in the current directory" -ForegroundColor Yellow
    exit 1
}

# Get default browser (simplified logic)
# Open showcase page
Write-Host "[Start] Opening showcase page..." -ForegroundColor Green
Write-Host ""

try {
    Start-Process $showcaseFile
    
    Write-Host "[OK] Showcase page opened!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[Info] 5 Core Services Showcased:" -ForegroundColor Cyan
    Write-Host "   1. GitLab    - http://192.168.76.141" -ForegroundColor White
    Write-Host "   2. Jenkins   - http://192.168.76.141:8080" -ForegroundColor White
    Write-Host "   3. Harbor    - http://192.168.76.141:5000" -ForegroundColor White
    Write-Host "   4. Prometheus - http://192.168.76.141:9090" -ForegroundColor White
    Write-Host "   5. Grafana   - http://192.168.76.141:3000" -ForegroundColor White
    Write-Host ""
    Write-Host "[Tip] Tips:" -ForegroundColor Yellow
    Write-Host "   - Click buttons on the page to quickly access services" -ForegroundColor Gray
    Write-Host "   - If services are not deployed, please run the deployment script first" -ForegroundColor Gray
    Write-Host "   - Ensure server IP is correct (Current: 192.168.76.141)" -ForegroundColor Gray
    Write-Host ""
    
    # Ask to check service status
    $check = Read-Host "Check service connection status? (y/N)"
    if ($check -eq "y" -or $check -eq "Y") {
        Write-Host ""
        Write-Host "[Check] Checking service connection status..." -ForegroundColor Cyan
        Write-Host ""
        
        $services = @(
            @{Name="GitLab"; Url="http://192.168.76.141"},
            @{Name="Jenkins"; Url="http://192.168.76.141:8080"},
            @{Name="Harbor"; Url="http://192.168.76.141:5000"},
            @{Name="Prometheus"; Url="http://192.168.76.141:9090"},
            @{Name="Grafana"; Url="http://192.168.76.141:3000"}
        )
        
        foreach ($service in $services) {
            Write-Host "Checking $($service.Name)..." -NoNewline -ForegroundColor Yellow
            try {
                $response = Invoke-WebRequest -Uri $service.Url -Method Head -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
                Write-Host " [OK] Accessible (Status: $($response.StatusCode))" -ForegroundColor Green
            } catch {
                Write-Host " [Error] Inaccessible" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Check complete!" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "[Error] Failed to open: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[Tip] Manual Open:" -ForegroundColor Yellow
    Write-Host "   1. Locate file: $((Get-Location).Path)\$showcaseFile" -ForegroundColor Gray
    Write-Host "   2. Right-click -> Open with -> Select Browser" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Good luck with the interview!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
