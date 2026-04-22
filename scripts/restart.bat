@echo off
chcp 65001 >nul
REM 实验室管理系统 - Windows一键重启脚本
REM 支持 Java/Python/Golang 前后端服务

setlocal enabledelayedexpansion

REM 加载配置
call "%~dp0deploy.conf.bat"

REM 颜色代码 (Windows 10+)
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=!ESC![91m"
set "GREEN=!ESC![92m"
set "YELLOW=!ESC![93m"
set "CYAN=!ESC![96m"
set "NC=!ESC![0m"

REM 日志函数
:log_info
echo %GREEN%[INFO]%NC% %date% %time% %~1
goto :eof

:log_warn
echo %YELLOW%[WARN]%NC% %date% %time% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %date% %time% %~1
goto :eof

:log_step
echo %CYAN%[STEP]%NC% %date% %time% %~1
goto :eof

REM 重启Java后端
:restart_java_backend
echo.
echo ==========================================
echo 重启Java后端服务
echo ==========================================
echo.

call "%~dp0stop.bat" backend
timeout /t 3 /nobreak >nul
call "%~dp0start.bat" backend

exit /b 0

REM 重启Java后端 (开发模式)
:restart_java_backend_dev
echo.
echo ==========================================
echo 重启Java后端服务 (开发模式)
echo ==========================================
echo.

call "%~dp0stop.bat" backend
timeout /t 3 /nobreak >nul
call "%~dp0start.bat" backend-dev

exit /b 0

REM 重启Python服务
:restart_python_service
echo.
echo ==========================================
echo 重启Python服务
echo ==========================================
echo.

call "%~dp0stop.bat" python
timeout /t 3 /nobreak >nul
call "%~dp0start.bat" python

exit /b 0

REM 重启Golang服务
:restart_golang_service
echo.
echo ==========================================
echo 重启Golang服务
echo ==========================================
echo.

call "%~dp0stop.bat" golang
timeout /t 3 /nobreak >nul
call "%~dp0start.bat" golang

exit /b 0

REM 重启前端服务
:restart_frontend
echo.
echo ==========================================
echo 重启前端服务
echo ==========================================
echo.

call "%~dp0stop.bat" frontend
timeout /t 3 /nobreak >nul
call "%~dp0start.bat" frontend

exit /b 0

REM 重启所有服务
:restart_all
echo.
echo ==========================================
echo 重启所有服务
echo ==========================================
echo.

call :log_step "停止所有服务..."
call "%~dp0stop.bat" all

echo.
call :log_info "等待5秒..."
timeout /t 5 /nobreak >nul

call :log_step "启动所有服务..."
call "%~dp0start.bat" all

echo.
echo ==========================================
echo 所有服务重启完成
echo ==========================================
echo.

exit /b 0

REM 优雅重启
:graceful_restart
echo.
echo ==========================================
echo 优雅重启所有服务
echo ==========================================
echo.

if "%JAVA_ENABLED%"=="true" (
    call :restart_java_backend
    timeout /t 5 /nobreak >nul
)

if "%PYTHON_ENABLED%"=="true" (
    call :restart_python_service
    timeout /t 3 /nobreak >nul
)

if "%GOLANG_ENABLED%"=="true" (
    call :restart_golang_service
    timeout /t 3 /nobreak >nul
)

if "%FRONTEND_ENABLED%"=="true" (
    call :restart_frontend
)

echo.
echo ==========================================
echo 优雅重启完成
echo ==========================================
echo.

exit /b 0

REM 显示帮助
:show_help
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   all         重启所有服务
echo   backend     重启Java后端服务
echo   backend-dev 重启Java后端服务 (开发模式)
echo   frontend    重启前端服务
echo   python      重启Python服务
echo   golang      重启Golang服务
echo   graceful    优雅重启所有服务 (逐个重启)
echo   help        显示帮助信息
echo.
echo 示例:
echo   %~nx0 all          # 重启所有服务
echo   %~nx0 backend      # 重启Java后端
echo   %~nx0 graceful     # 优雅重启所有服务
goto :eof

REM 主函数
set action=%1
if "%action%"=="" set action=all

if "%action%"=="all" goto restart_all
if "%action%"=="backend" goto restart_java_backend
if "%action%"=="backend-dev" goto restart_java_backend_dev
if "%action%"=="frontend" goto restart_frontend
if "%action%"=="python" goto restart_python_service
if "%action%"=="golang" goto restart_golang_service
if "%action%"=="graceful" goto graceful_restart
if "%action%"=="help" goto show_help
if "%action%"=="--help" goto show_help
if "%action%"=="-h" goto show_help

call :log_error "未知选项: %action%"
call :show_help
exit /b 1
