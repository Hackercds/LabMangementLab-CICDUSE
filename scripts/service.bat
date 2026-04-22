@echo off
chcp 65001 >nul
REM 实验室管理系统 - Windows统一服务管理脚本
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

REM 显示状态
:show_status
echo.
echo ==========================================
echo         服务状态概览
echo ==========================================
echo.
echo 服务名称            状态            端口
echo ------------------------------------------------------------------------

REM Java后端
if "%JAVA_ENABLED%"=="true" (
    set status=%RED%已停止%NC%
    netstat -ano | findstr ":%JAVA_PORT% " | findstr "LISTENING" >nul 2>&1
    if !errorlevel!==0 set status=%GREEN%运行中%NC%
    echo Java后端            !status!          %JAVA_PORT%
)

REM Python服务
if "%PYTHON_ENABLED%"=="true" (
    set status=%RED%已停止%NC%
    netstat -ano | findstr ":%PYTHON_PORT% " | findstr "LISTENING" >nul 2>&1
    if !errorlevel!==0 set status=%GREEN%运行中%NC%
    echo Python服务          !status!          %PYTHON_PORT%
)

REM Golang服务
if "%GOLANG_ENABLED%"=="true" (
    set status=%RED%已停止%NC%
    netstat -ano | findstr ":%GOLANG_PORT% " | findstr "LISTENING" >nul 2>&1
    if !errorlevel!==0 set status=%GREEN%运行中%NC%
    echo Golang服务          !status!          %GOLANG_PORT%
)

REM 前端
if "%FRONTEND_ENABLED%"=="true" (
    set status=%RED%已停止%NC%
    netstat -ano | findstr ":%FRONTEND_PORT% " | findstr "LISTENING" >nul 2>&1
    if !errorlevel!==0 set status=%GREEN%运行中%NC%
    echo 前端服务            !status!          %FRONTEND_PORT%
)

echo.
echo ==========================================
echo         守护进程状态
echo ==========================================
echo.

if exist "%PID_DIR%\daemon.pid" (
    set /p daemon_pid=<%PID_DIR%\daemon.pid
    tasklist /fi "pid eq !daemon_pid!" 2>nul | find "pid" >nul
    if !errorlevel!==0 (
        echo 守护进程: %GREEN%运行中%NC% (PID: !daemon_pid!)
    ) else (
        echo 守护进程: %RED%已停止%NC%
    )
) else (
    echo 守护进程: %RED%已停止%NC%
)

echo.
exit /b 0

REM 健康检查
:health_check
echo.
echo ==========================================
echo         健康检查
echo ==========================================
echo.

if "%JAVA_ENABLED%"=="true" (
    echo|set /p="Java后端: "
    curl -sf --connect-timeout 5 "http://localhost:%JAVA_PORT%/api/actuator/health" >nul 2>&1
    if !errorlevel!==0 (
        echo %GREEN%健康%NC%
    ) else (
        echo %RED%不健康%NC%
    )
)

if "%FRONTEND_ENABLED%"=="true" (
    echo|set /p="前端服务: "
    curl -sf --connect-timeout 5 "http://localhost:%FRONTEND_PORT%" >nul 2>&1
    if !errorlevel!==0 (
        echo %GREEN%正常%NC%
    ) else (
        echo %RED%异常%NC%
    )
)

echo.
exit /b 0

REM 显示帮助
:show_help
echo.
echo ==========================================
echo    实验室管理系统 - 服务管理工具
echo ==========================================
echo.
echo 用法: %~nx0 ^<命令^> [选项]
echo.
echo %YELLOW%服务管理命令:%NC%
echo   start [服务]     启动服务 (all/backend/frontend/python/golang)
echo   stop [服务]      停止服务 (all/backend/frontend/python/golang/force)
echo   restart [服务]   重启服务 (all/backend/frontend/python/golang/graceful)
echo   status           查看所有服务状态
echo   health           健康检查
echo.
echo %YELLOW%日志命令:%NC%
echo   logs [服务]      查看服务日志 (backend/frontend/python/golang)
echo.
echo %YELLOW%项目命令:%NC%
echo   init             初始化项目环境
echo   build            构建项目
echo   clean            清理项目
echo.
echo %YELLOW%其他命令:%NC%
echo   help             显示帮助信息
echo   version          显示版本信息
echo.
echo %YELLOW%示例:%NC%
echo   %~nx0 start all              # 启动所有服务
echo   %~nx0 start backend          # 启动Java后端
echo   %~nx0 stop all               # 停止所有服务
echo   %~nx0 restart all            # 重启所有服务
echo.
goto :eof

REM 显示版本
:show_version
echo 实验室管理系统 - 服务管理工具 v1.0.0
echo 支持: Java / Python / Golang / Node.js
goto :eof

REM 主函数
set command=%1
if "%command%"=="" set command=help

if "%command%"=="start" (
    shift
    call "%~dp0start.bat" %1
    exit /b %errorlevel%
)
if "%command%"=="stop" (
    shift
    call "%~dp0stop.bat" %1
    exit /b %errorlevel%
)
if "%command%"=="restart" (
    shift
    call "%~dp0restart.bat" %1
    exit /b %errorlevel%
)
if "%command%"=="status" goto show_status
if "%command%"=="health" goto health_check
if "%command%"=="logs" (
    shift
    set service=%1
    if "!service!"=="" set service=backend
    type "%LOG_DIR%\!service!.log" 2>nul || echo 日志文件不存在
    exit /b 0
)
if "%command%"=="help" goto show_help
if "%command%"=="--help" goto show_help
if "%command%"=="-h" goto show_help
if "%command%"=="version" goto show_version
if "%command%"=="--version" goto show_version
if "%command%"=="-v" goto show_version

echo %RED%[ERROR]%NC% 未知命令: %command%
call :show_help
exit /b 1
