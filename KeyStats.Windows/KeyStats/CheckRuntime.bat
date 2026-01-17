@echo off
REM KeyStats Runtime Check Launcher
REM 检查 .NET 8.0 Desktop Runtime 并启动应用

setlocal

REM 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "EXE_PATH=%SCRIPT_DIR%KeyStats.exe"

REM 检查 KeyStats.exe 是否存在
if not exist "%EXE_PATH%" (
    echo 错误：找不到 KeyStats.exe 文件。
    pause
    exit /b 1
)

REM 尝试运行 PowerShell 检查脚本（如果存在）
if exist "%SCRIPT_DIR%CheckRuntime.ps1" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%CheckRuntime.ps1"
    if errorlevel 1 (
        exit /b 1
    )
) else (
    REM 如果没有 PowerShell 脚本，直接尝试运行应用
    REM Windows 会在缺少运行时显示系统错误对话框
    start "" "%EXE_PATH%"
)

endlocal
