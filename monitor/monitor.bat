@echo off
chcp 65001 >nul
REM 实验室管理系统 - Windows监控服务启动脚本
REM 启动 Prometheus + Grafana 监控系统

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

REM 颜色代码
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=!ESC![91m"
set "GREEN=!ESC![92m"
set "YELLOW=!ESC![93m"
set "CYAN=!ESC![96m"
set "NC=!ESC![0m"

REM 检查Docker
:check_docker
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Docker未安装，请先安装Docker Desktop
    exit /b 1
)

where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Docker Compose未安装
    exit /b 1
)

exit /b 0

REM 启动监控服务
:start_monitoring
echo %CYAN%[STEP]%NC% 启动监控服务...

cd /d "%SCRIPT_DIR%"

REM 创建必要目录
if not exist "prometheus" mkdir prometheus
if not exist "alertmanager" mkdir alertmanager
if not exist "grafana\provisioning\datasources" mkdir grafana\provisioning\datasources
if not exist "grafana\provisioning\dashboards" mkdir grafana\provisioning\dashboards
if not exist "blackbox" mkdir blackbox

REM 启动服务
docker-compose -f docker-compose.monitoring.yml up -d

echo %GREEN%[INFO]%NC% 等待服务启动...
timeout /t 10 /nobreak >nul

REM 检查服务状态
echo %GREEN%[INFO]%NC% 服务状态:
docker-compose -f docker-compose.monitoring.yml ps

echo.
echo ==========================================
echo 监控服务已启动
echo ==========================================
echo.
echo 访问地址:
echo   Prometheus:   http://localhost:9090
echo   Grafana:      http://localhost:3001 ^(admin/admin123^)
echo   Alertmanager: http://localhost:9093
echo   cAdvisor:     http://localhost:8080
echo.

exit /b 0

REM 停止监控服务
:stop_monitoring
echo %CYAN%[STEP]%NC% 停止监控服务...

cd /d "%SCRIPT_DIR%"
docker-compose -f docker-compose.monitoring.yml down

echo %GREEN%[INFO]%NC% 监控服务已停止
exit /b 0

REM 重启监控服务
:restart_monitoring
call :stop_monitoring
timeout /t 3 /nobreak >nul
call :start_monitoring
exit /b 0

REM 查看监控服务状态
:status_monitoring
echo %GREEN%[INFO]%NC% 监控服务状态:
cd /d "%SCRIPT_DIR%"
docker-compose -f docker-compose.monitoring.yml ps
exit /b 0

REM 显示帮助
:show_help
echo 用法: %~nx0 ^<命令^>
echo.
echo 命令:
echo   start     启动监控服务
echo   stop      停止监控服务
echo   restart   重启监控服务
echo   status    查看服务状态
echo   help      显示帮助信息
echo.
echo 示例:
echo   %~nx0 start    # 启动监控服务
echo   %~nx0 status   # 查看服务状态
goto :eof

REM 主函数
call :check_docker
if %errorlevel% neq 0 exit /b 1

set command=%1
if "%command%"=="" set command=help

if "%command%"=="start" goto start_monitoring
if "%command%"=="stop" goto stop_monitoring
if "%command%"=="restart" goto restart_monitoring
if "%command%"=="status" goto status_monitoring
if "%command%"=="help" goto show_help
if "%command%"=="--help" goto show_help
if "%command%"=="-h" goto show_help

echo %RED%[ERROR]%NC% 未知命令: %command%
call :show_help
exit /b 1
