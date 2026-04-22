@echo off
chcp 65001 >nul
REM 实验室管理系统 - Windows一键停止脚本
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

REM 停止服务
:stop_service
setlocal
set service_name=%~1
set port=%~2

call :log_step "停止服务: %service_name%"

set pid_file=%PID_DIR%\%service_name%.pid
set stopped=false

REM 方法1: 通过PID文件停止
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    
    tasklist /fi "pid eq !pid!" 2>nul | find "pid" >nul
    if !errorlevel!==0 (
        call :log_info "发送终止信号到进程 !pid!..."
        taskkill /pid !pid! /f >nul 2>&1
        set stopped=true
    )
    
    del /f /q "%pid_file%" >nul 2>&1
)

REM 方法2: 通过端口停止
if not "%port%"=="" (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%port% " ^| findstr "LISTENING"') do (
        call :log_info "通过端口 %port% 停止进程 %%a..."
        taskkill /pid %%a /f >nul 2>&1
        set stopped=true
    )
)

REM 方法3: 通过进程名停止
if "%service_name%"=="backend" (
    for /f "tokens=2" %%a in ('tasklist /fi "imagename eq java.exe" /fo list ^| find "PID:"') do (
        call :log_info "通过进程名停止进程 %%a..."
        taskkill /pid %%a /f >nul 2>&1
        set stopped=true
    )
)

if "%service_name%"=="frontend" (
    for /f "tokens=2" %%a in ('tasklist /fi "imagename eq node.exe" /fo list ^| find "PID:"') do (
        call :log_info "通过进程名停止进程 %%a..."
        taskkill /pid %%a /f >nul 2>&1
        set stopped=true
    )
)

if "%stopped%"=="false" (
    call :log_warn "服务 %service_name% 未运行"
)

endlocal
goto :eof

REM 停止Java后端
:stop_java_backend
call :stop_service "%JAVA_SERVICE_NAME%" "%JAVA_PORT%"
goto :eof

REM 停止Python服务
:stop_python_service
call :stop_service "%PYTHON_SERVICE_NAME%" "%PYTHON_PORT%"
goto :eof

REM 停止Golang服务
:stop_golang_service
call :stop_service "%GOLANG_SERVICE_NAME%" "%GOLANG_PORT%"
goto :eof

REM 停止前端服务
:stop_frontend
call :stop_service "%FRONTEND_SERVICE_NAME%" "%FRONTEND_PORT%"
goto :eof

REM 停止所有服务
:stop_all
echo.
echo ==========================================
echo 停止所有服务
echo ==========================================
echo.

if "%FRONTEND_ENABLED%"=="true" call :stop_frontend
if "%GOLANG_ENABLED%"=="true" call :stop_golang_service
if "%PYTHON_ENABLED%"=="true" call :stop_python_service
if "%JAVA_ENABLED%"=="true" call :stop_java_backend

echo.
echo ==========================================
echo 所有服务已停止
echo ==========================================
echo.

exit /b 0

REM 强制停止所有服务
:force_stop_all
call :log_warn "强制停止所有服务..."

REM 停止所有Java进程
taskkill /f /im java.exe >nul 2>&1

REM 停止所有Node进程
taskkill /f /im node.exe >nul 2>&1

REM 停止所有Python进程
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im python3.exe >nul 2>&1

REM 清理PID文件
del /f /q "%PID_DIR%\*.pid" >nul 2>&1

call :log_info "强制停止完成"
exit /b 0

REM 显示帮助
:show_help
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   all         停止所有服务
echo   backend     停止Java后端服务
echo   frontend    停止前端服务
echo   python      停止Python服务
echo   golang      停止Golang服务
echo   force       强制停止所有服务
echo   help        显示帮助信息
echo.
echo 示例:
echo   %~nx0 all          # 停止所有服务
echo   %~nx0 backend      # 停止Java后端
echo   %~nx0 force        # 强制停止所有服务
goto :eof

REM 主函数
set action=%1
if "%action%"=="" set action=all

if "%action%"=="all" goto stop_all
if "%action%"=="backend" goto stop_java_backend
if "%action%"=="frontend" goto stop_frontend
if "%action%"=="python" goto stop_python_service
if "%action%"=="golang" goto stop_golang_service
if "%action%"=="force" goto force_stop_all
if "%action%"=="help" goto show_help
if "%action%"=="--help" goto show_help
if "%action%"=="-h" goto show_help

call :log_error "未知选项: %action%"
call :show_help
exit /b 1
