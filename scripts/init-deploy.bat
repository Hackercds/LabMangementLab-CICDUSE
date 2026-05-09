@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
set "CFG=%PROJECT_ROOT%\config\config.yaml"

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║          实验室管理系统 - 一键部署 (Windows)               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: 检查Docker
echo [检查] Docker...
docker info >nul 2>&1
if %errorlevel% neq 0 (echo [错误] Docker未运行！&& pause && exit /b 1)
echo [通过] Docker OK

:: 从 config.yaml 加载配置 (用 PowerShell 解析)
echo [配置] 加载 config\config.yaml ...
if not exist "%CFG%" (echo [错误] %CFG% 不存在！&& pause && exit /b 1)

for /f "usebackq tokens=*" %%a in (`powershell -Command "
    $y=Get-Content '%CFG%' -Raw|ConvertFrom-Yaml -ErrorAction SilentlyContinue;
    if(-not $y){Write-Host 'FAIL';exit}
    Write-Host \"HOST_IP=$($y.app.host)\";
    Write-Host \"BACKEND_PORT=$($y.app.backend_port)\";
    Write-Host \"FRONTEND_PORT=$($y.app.frontend_port)\";
    Write-Host \"MYSQL_DATABASE=$($y.database.name)\";
    Write-Host \"MYSQL_USER=$($y.database.user)\";
    Write-Host \"MYSQL_ROOT_PASSWORD=$($y.database.root_password)\";
    Write-Host \"MYSQL_PASSWORD=$($y.database.app_password)\";
    Write-Host \"SPRING_PROFILES_ACTIVE=$($y.spring.profiles_active)\";
    Write-Host \"CORS_ALLOWED_ORIGINS=$($y.cors.allowed_origins)\";
    Write-Host \"JWT_SECRET=$($y.jwt.secret)\";
    Write-Host \"JWT_EXPIRATION=$($y.jwt.expiration)\"
" 2^>nul`) do set "%%a"

if "%HOST_IP%"=="" (
    echo [警告] PowerShell 解析失败，使用PowerShell安装powershell-yaml模块或手动设置变量
    echo    Install-Module -Name powershell-yaml -Force
    pause
    exit /b 1
)
echo [配置] 主机=%HOST_IP% 后端端口=%BACKEND_PORT%

:: 停止旧容器
echo [清理] 停止旧容器...
docker stop lab-frontend lab-backend lab-redis lab-mysql 2>nul
docker rm lab-frontend lab-backend lab-redis lab-mysql 2>nul

:: 构建
echo [构建] 构建镜像...
docker build -t lab-backend "%PROJECT_ROOT%\backend"
docker build -t lab-frontend "%PROJECT_ROOT%\frontend"

:: 网络与卷
docker network create lab-network 2>nul

:: MySQL
echo [启动] MySQL...
docker run -d --name lab-mysql --restart always --network lab-network --network-alias mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=%MYSQL_ROOT_PASSWORD% -e MYSQL_DATABASE=%MYSQL_DATABASE% -e MYSQL_USER=%MYSQL_USER% -e MYSQL_PASSWORD=%MYSQL_PASSWORD% -e TZ=Asia/Shanghai -v lab-mysql-data:/var/lib/mysql mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password

echo [等待] MySQL...
timeout /t 15 /nobreak >nul

echo [初始化] 导入数据库...
type "%PROJECT_ROOT%\backend\src\main\resources\db\schema.sql" | docker exec -i lab-mysql mysql -u root -p%MYSQL_ROOT_PASSWORD% -f %MYSQL_DATABASE% 2>nul || echo   (重复键可忽略)

:: Redis
echo [启动] Redis...
docker run -d --name lab-redis --restart always --network lab-network --network-alias redis -p 6379:6379 -v lab-redis-data:/data redis:7-alpine redis-server --appendonly yes
timeout /t 3 /nobreak >nul

:: 后端
echo [启动] 后端...
docker run -d --name lab-backend --restart always --network lab-network --network-alias backend -p %BACKEND_PORT%:%BACKEND_PORT% -e SPRING_PROFILES_ACTIVE=%SPRING_PROFILES_ACTIVE% -e SERVER_PORT=%BACKEND_PORT% -e DB_HOST=mysql -e DB_PORT=3306 -e DB_NAME=%MYSQL_DATABASE% -e DB_USERNAME=%MYSQL_USER% -e DB_PASSWORD=%MYSQL_PASSWORD% -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD= -e REDIS_DATABASE=0 -e JWT_SECRET=%JWT_SECRET% -e JWT_EXPIRATION=%JWT_EXPIRATION% -e CORS_ALLOWED_ORIGINS=%CORS_ALLOWED_ORIGINS% lab-backend

:: 前端
echo [启动] 前端...
docker run -d --name lab-frontend --restart always --network lab-network -p %FRONTEND_PORT%:80 lab-frontend

:: 等待
echo [等待] 服务启动中...
timeout /t 30 /nobreak >nul

curl -s http://%HOST_IP%:%BACKEND_PORT%/api/actuator/health 2>nul

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                      部署完成！                            ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  前端: http://%HOST_IP%:%FRONTEND_PORT%                          ║
echo ║  后端: http://%HOST_IP%:%BACKEND_PORT%/api                         ║
echo ║  账号: admin / admin123                               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
pause
