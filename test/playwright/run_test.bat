@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo ╔══════════════════════════════════════════════╗
echo ║    实验室管理系统 - Playwright 前端测试      ║
echo ╚══════════════════════════════════════════════╝
echo.

:: 检查 Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Node.js 未安装
    pause
    exit /b 1
)

:: 安装依赖 (首次)
if not exist "node_modules" (
    echo [安装] Playwright 测试依赖...
    npm install
    npx playwright install chromium
)

echo.
echo 选择运行方式:
echo   [1] 全部测试 (无界面)
echo   [2] 全部测试 (有界面)
echo   [3] 仅 Chrome
echo   [4] 调试模式
echo   [5] 查看上次报告
echo   [0] 退出
echo.
set /p choice="请输入: "

if "%choice%"=="1" npx playwright test
if "%choice%"=="2" npx playwright test --headed
if "%choice%"=="3" npx playwright test --project=chromium --headed
if "%choice%"=="4" npx playwright test --debug
if "%choice%"=="5" npx playwright show-report reports
if "%choice%"=="0" exit /b 0

pause
