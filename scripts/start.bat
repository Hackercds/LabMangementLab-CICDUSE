@echo off
chcp 65001 >nul
REM 实验室管理系统 - Windows一键启动脚本
REM 支持 Java/Python/Golang 前后端服务

setlocal enabledelayedexpansion

REM 加载配置
call "%~dp0deploy.conf.bat"

REM 颜色代码 (Windows 10+)
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=!ESC![91m"
set "GREEN=!ESC![92m"
set "YELLOW=!ESC![93m"
set "BLUE=!ESC![94m"
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

:log_success
echo %GREEN%[SUCCESS]%NC% %date% %time% %~1
goto :eof

REM 检查端口是否被占用
:check_port
netstat -ano | findstr ":%~1 " | findstr "LISTENING" >nul 2>&1
goto :eof

REM 等待端口监听
:wait_for_port
setlocal
set port=%~1
set max_wait=%~2
if "%max_wait%"=="" set max_wait=60
set wait_time=0

:wait_loop
call :check_port %port%
if %errorlevel%==0 (
    endlocal
    exit /b 0
)
if %wait_time% geq %max_wait% (
    endlocal
    exit /b 1
)
timeout /t 2 /nobreak >nul
set /a wait_time+=2
goto wait_loop

REM 检查命令是否存在
:check_command
where %~1 >nul 2>&1
goto :eof

REM 启动Java后端服务
:start_java_backend
call :log_step "启动Java后端服务..."

set pid_file=%PID_DIR%\%JAVA_SERVICE_NAME%.pid
set log_file=%LOG_DIR%\%JAVA_SERVICE_NAME%.log

REM 检查是否已运行
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    tasklist /fi "pid eq !pid!" 2>nul | find "java" >nul
    if !errorlevel!==0 (
        call :log_warn "Java后端服务已在运行 (PID: !pid!)"
        exit /b 0
    )
)

REM 检查端口
call :check_port %JAVA_PORT%
if %errorlevel%==0 (
    call :log_error "端口 %JAVA_PORT% 已被占用"
    exit /b 1
)

REM 检查Java环境
call :check_command java
if %errorlevel% neq 0 (
    call :log_error "请先安装Java环境"
    exit /b 1
)

REM 检查Maven
call :check_command mvn
if %errorlevel% neq 0 (
    call :log_error "请先安装Maven"
    exit /b 1
)

cd /d "%JAVA_SOURCE_PATH%"

REM 检查是否需要编译
if not exist "%JAVA_JAR_PATH%" (
    call :log_info "编译Java项目..."
    call mvn clean package %JAVA_MAVEN_OPTS% -q
    if !errorlevel! neq 0 (
        call :log_error "Java项目编译失败"
        exit /b 1
    )
)

REM 启动服务
call :log_info "启动Java服务 (端口: %JAVA_PORT%)..."
start /b java %JAVA_JVM_OPTS% -jar "%JAVA_JAR_PATH%" --server.port=%JAVA_PORT% --spring.profiles.active=%JAVA_SPRING_PROFILE% > "%log_file%" 2>&1

REM 获取PID
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq java.exe" /fo list ^| find "PID:"') do (
    echo %%a > "%pid_file%"
)

REM 等待启动
call :wait_for_port %JAVA_PORT% 60
if %errorlevel%==0 (
    call :log_success "Java后端服务启动成功 (Port: %JAVA_PORT%)"
    
    REM 健康检查
    timeout /t 5 /nobreak >nul
    curl -sf "http://localhost:%JAVA_PORT%/api/actuator/health" >nul 2>&1
    if !errorlevel!==0 (
        call :log_success "Java后端服务健康检查通过"
    ) else (
        call :log_warn "Java后端服务健康检查失败，请检查日志: %log_file%"
    )
    exit /b 0
) else (
    call :log_error "Java后端服务启动超时"
    exit /b 1
)

REM 启动Java后端服务 (开发模式)
:start_java_backend_dev
call :log_step "启动Java后端服务 (开发模式)..."

set pid_file=%PID_DIR%\%JAVA_SERVICE_NAME%.pid
set log_file=%LOG_DIR%\%JAVA_SERVICE_NAME%.log

REM 检查是否已运行
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    tasklist /fi "pid eq !pid!" 2>nul | find "java" >nul
    if !errorlevel!==0 (
        call :log_warn "Java后端服务已在运行 (PID: !pid!)"
        exit /b 0
    )
)

REM 检查端口
call :check_port %JAVA_PORT%
if %errorlevel%==0 (
    call :log_error "端口 %JAVA_PORT% 已被占用"
    exit /b 1
)

REM 检查Maven
call :check_command mvn
if %errorlevel% neq 0 (
    call :log_error "请先安装Maven"
    exit /b 1
)

cd /d "%JAVA_SOURCE_PATH%"

REM 使用Maven启动
call :log_info "使用 mvn spring-boot:run 启动..."
start /b mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=%JAVA_PORT% --spring.profiles.active=%JAVA_SPRING_PROFILE%" > "%log_file%" 2>&1

REM 等待启动
call :wait_for_port %JAVA_PORT% 90
if %errorlevel%==0 (
    call :log_success "Java后端服务启动成功 (Port: %JAVA_PORT%)"
    exit /b 0
) else (
    call :log_error "Java后端服务启动超时"
    exit /b 1
)

REM 启动Python服务
:start_python_service
call :log_step "启动Python服务..."

set pid_file=%PID_DIR%\%PYTHON_SERVICE_NAME%.pid
set log_file=%LOG_DIR%\%PYTHON_SERVICE_NAME%.log

REM 检查是否已运行
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    tasklist /fi "pid eq !pid!" 2>nul | find "python" >nul
    if !errorlevel!==0 (
        call :log_warn "Python服务已在运行 (PID: !pid!)"
        exit /b 0
    )
)

REM 检查端口
call :check_port %PYTHON_PORT%
if %errorlevel%==0 (
    call :log_error "端口 %PYTHON_PORT% 已被占用"
    exit /b 1
)

REM 检查Python
call :check_command python
if %errorlevel% neq 0 (
    call :check_command python3
    if !errorlevel! neq 0 (
        call :log_error "请先安装Python"
        exit /b 1
    )
    set python_cmd=python3
) else (
    set python_cmd=python
)

REM 激活虚拟环境
if exist "%PYTHON_VENV_PATH%\Scripts\activate.bat" (
    call :log_info "激活Python虚拟环境..."
    call "%PYTHON_VENV_PATH%\Scripts\activate.bat"
)

REM 安装依赖
if exist "%PYTHON_REQUIREMENTS%" (
    call :log_info "安装Python依赖..."
    %python_cmd% -m pip install -r "%PYTHON_REQUIREMENTS%" -q
)

REM 启动服务
call :log_info "启动Python服务 (端口: %PYTHON_PORT%)..."
start /b %python_cmd% "%PYTHON_SCRIPT_PATH%" --port %PYTHON_PORT% > "%log_file%" 2>&1

REM 等待启动
call :wait_for_port %PYTHON_PORT% 30
if %errorlevel%==0 (
    call :log_success "Python服务启动成功 (Port: %PYTHON_PORT%)"
    exit /b 0
) else (
    call :log_error "Python服务启动超时"
    exit /b 1
)

REM 启动Golang服务
:start_golang_service
call :log_step "启动Golang服务..."

set pid_file=%PID_DIR%\%GOLANG_SERVICE_NAME%.pid
set log_file=%LOG_DIR%\%GOLANG_SERVICE_NAME%.log

REM 检查是否已运行
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    tasklist /fi "pid eq !pid!" 2>nul | find "server" >nul
    if !errorlevel!==0 (
        call :log_warn "Golang服务已在运行 (PID: !pid!)"
        exit /b 0
    )
)

REM 检查端口
call :check_port %GOLANG_PORT%
if %errorlevel%==0 (
    call :log_error "端口 %GOLANG_PORT% 已被占用"
    exit /b 1
)

REM 检查Go
call :check_command go
if %errorlevel% neq 0 (
    call :log_error "请先安装Go环境"
    exit /b 1
)

REM 编译（如果需要）
if not exist "%GOLANG_BINARY_PATH%" (
    call :log_info "编译Golang项目..."
    cd /d "%GOLANG_SOURCE_PATH%"
    go build -o "%GOLANG_BINARY_PATH%" .
    if !errorlevel! neq 0 (
        call :log_error "Golang项目编译失败"
        exit /b 1
    )
)

REM 启动服务
call :log_info "启动Golang服务 (端口: %GOLANG_PORT%)..."
start /b "%GOLANG_BINARY_PATH%" --port %GOLANG_PORT% > "%log_file%" 2>&1

REM 等待启动
call :wait_for_port %GOLANG_PORT% 30
if %errorlevel%==0 (
    call :log_success "Golang服务启动成功 (Port: %GOLANG_PORT%)"
    exit /b 0
) else (
    call :log_error "Golang服务启动超时"
    exit /b 1
)

REM 启动前端服务
:start_frontend
call :log_step "启动前端服务..."

set pid_file=%PID_DIR%\%FRONTEND_SERVICE_NAME%.pid
set log_file=%LOG_DIR%\%FRONTEND_SERVICE_NAME%.log

REM 检查是否已运行
if exist "%pid_file%" (
    set /p pid=<%pid_file%
    tasklist /fi "pid eq !pid!" 2>nul | find "node" >nul
    if !errorlevel!==0 (
        call :log_warn "前端服务已在运行 (PID: !pid!)"
        exit /b 0
    )
)

REM 检查端口
call :check_port %FRONTEND_PORT%
if %errorlevel%==0 (
    call :log_error "端口 %FRONTEND_PORT% 已被占用"
    exit /b 1
)

REM 检查Node.js
call :check_command node
if %errorlevel% neq 0 (
    call :log_error "请先安装Node.js"
    exit /b 1
)

REM 检查npm
call :check_command npm
if %errorlevel% neq 0 (
    call :log_error "请先安装npm"
    exit /b 1
)

cd /d "%FRONTEND_SOURCE_PATH%"

REM 安装依赖
if not exist "node_modules" (
    call :log_info "安装前端依赖..."
    call npm install --silent
)

REM 启动开发服务器
call :log_info "启动前端开发服务器 (端口: %FRONTEND_PORT%)..."
start /b npm run dev -- --port %FRONTEND_PORT% > "%log_file%" 2>&1

REM 等待启动
call :wait_for_port %FRONTEND_PORT% 60
if %errorlevel%==0 (
    call :log_success "前端服务启动成功 (Port: %FRONTEND_PORT%)"
    call :log_info "访问地址: http://localhost:%FRONTEND_PORT%"
    exit /b 0
) else (
    call :log_error "前端服务启动超时"
    exit /b 1
)

REM 启动所有服务
:start_all
echo.
echo ==========================================
echo 启动所有服务
echo ==========================================
echo.

if "%JAVA_ENABLED%"=="true" call :start_java_backend
if "%PYTHON_ENABLED%"=="true" call :start_python_service
if "%GOLANG_ENABLED%"=="true" call :start_golang_service
if "%FRONTEND_ENABLED%"=="true" (
    timeout /t 5 /nobreak >nul
    call :start_frontend
)

echo.
echo ==========================================
echo 所有服务启动完成
echo ==========================================
echo.
echo 服务地址:
if "%JAVA_ENABLED%"=="true" echo   后端API: http://localhost:%JAVA_PORT%
if "%FRONTEND_ENABLED%"=="true" echo   前端页面: http://localhost:%FRONTEND_PORT%
if "%PYTHON_ENABLED%"=="true" echo   Python服务: http://localhost:%PYTHON_PORT%
if "%GOLANG_ENABLED%"=="true" echo   Golang服务: http://localhost:%GOLANG_PORT%
echo.

exit /b 0

REM 显示帮助
:show_help
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   all         启动所有服务
echo   backend     启动Java后端服务
echo   backend-dev 启动Java后端服务 (开发模式)
echo   frontend    启动前端服务
echo   python      启动Python服务
echo   golang      启动Golang服务
echo   help        显示帮助信息
echo.
echo 示例:
echo   %~nx0 all          # 启动所有服务
echo   %~nx0 backend      # 启动Java后端
echo   %~nx0 frontend     # 启动前端
goto :eof

REM 主函数
set action=%1
if "%action%"=="" set action=all

if "%action%"=="all" goto start_all
if "%action%"=="backend" goto start_java_backend
if "%action%"=="backend-dev" goto start_java_backend_dev
if "%action%"=="frontend" goto start_frontend
if "%action%"=="python" goto start_python_service
if "%action%"=="golang" goto start_golang_service
if "%action%"=="help" goto show_help
if "%action%"=="--help" goto show_help
if "%action%"=="-h" goto show_help

call :log_error "未知选项: %action%"
call :show_help
exit /b 1
