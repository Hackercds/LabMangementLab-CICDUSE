@echo off
:: 实验室管理系统 - 裸机启动入口
:: 此脚本自动请求管理员权限并调用 PowerShell 部署脚本
:: 双击此文件即可运行

cd /d "%~dp0.."

:: 检查是否以管理员运行
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 调用 PowerShell 脚本
powershell -ExecutionPolicy Bypass -File "%~dp0raw_start.ps1"
pause
