# KeyStats Runtime Check Script
# 检查 .NET 8.0 Desktop Runtime 是否已安装

$ErrorActionPreference = "Continue"

# 检查 .NET Runtime 是否已安装
function Test-DotNetRuntime {
    try {
        # 尝试运行 dotnet --list-runtimes 命令
        $output = & dotnet --list-runtimes 2>&1
        if ($LASTEXITCODE -eq 0 -and $output) {
            # 检查是否包含 .NET 8.0 Desktop Runtime
            $hasDesktopRuntime = $output | Where-Object { $_ -match "Microsoft\.WindowsDesktop\.App\s+8\.0" }
            return $null -ne $hasDesktopRuntime
        }
        return $false
    }
    catch {
        return $false
    }
}

# 检查运行时
if (-not (Test-DotNetRuntime)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "需要安装 .NET 8.0 Desktop Runtime" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "按键统计需要安装 .NET 8.0 Desktop Runtime 才能运行。" -ForegroundColor White
    Write-Host ""
    Write-Host "请按照以下步骤安装：" -ForegroundColor Cyan
    Write-Host "1. 访问：https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor White
    Write-Host "2. 下载 'Desktop Runtime'（约 50MB）" -ForegroundColor White
    Write-Host "3. 双击安装即可" -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "是否现在打开下载页面？(Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "https://dotnet.microsoft.com/download/dotnet/8.0"
    }
    
    Write-Host ""
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# 运行时已安装，启动应用
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptPath "KeyStats.exe"

if (Test-Path $exePath) {
    Write-Host "正在启动 KeyStats..." -ForegroundColor Green
    Start-Process -FilePath $exePath
} else {
    Write-Host "错误：找不到 KeyStats.exe 文件。" -ForegroundColor Red
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
