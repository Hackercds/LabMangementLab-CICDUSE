@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║          实验室管理系统 - 一键部署 (Windows)               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: 检查Docker
echo [检查] Docker环境...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker未运行！请先启动Docker Desktop
    pause
    exit /b 1
)
echo [通过] Docker运行正常

:: 加载配置
echo [配置] 加载环境变量...
if exist "%PROJECT_ROOT%\.env" (
    for /f "usebackq tokens=*" %%a in ("%PROJECT_ROOT%\.env") do (
        set "%%a"
    )
    echo [配置] 加载完成
) else (
    echo [警告] .env文件不存在，使用默认配置
)

:: 停止旧容器
echo [清理] 停止旧容器...
docker stop lab-frontend lab-backend lab-redis lab-mysql 2>nul
docker rm lab-frontend lab-backend lab-redis lab-mysql 2>nul

:: 构建镜像
echo [构建] 构建Docker镜像...
docker build -t lab-backend "%PROJECT_ROOT%\backend"
docker build -t lab-frontend "%PROJECT_ROOT%\frontend"
echo [完成] 镜像构建完成

:: 创建网络
docker network create lab-network 2>nul

:: 启动MySQL
echo [启动] MySQL...
docker run -d --name lab-mysql --restart always --network lab-network --network-alias mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=%MYSQL_ROOT_PASSWORD% -e MYSQL_DATABASE=%MYSQL_DATABASE% -e MYSQL_USER=%MYSQL_USER% -e MYSQL_PASSWORD=%MYSQL_PASSWORD% -e TZ=Asia/Shanghai -v lab-mysql-data:/var/lib/mysql mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password

echo [等待] MySQL启动中...
timeout /t 15 /nobreak >nul

:: 初始化数据库
echo [初始化] 导入数据库...
type "%PROJECT_ROOT%\backend\src\main\resources\db\schema.sql" | docker exec -i lab-mysql mysql -u root -p%MYSQL_ROOT_PASSWORD%
echo [完成] 数据库初始化完成

:: 启动Redis
echo [启动] Redis...
docker run -d --name lab-redis --restart always --network lab-network --network-alias redis -p 6379:6379 -v lab-redis-data:/data redis:7-alpine redis-server --appendonly yes

timeout /t 3 /nobreak >nul

:: 启动后端
echo [启动] 后端服务...
docker run -d --name lab-backend --restart always --network lab-network --network-alias backend -p %BACKEND_PORT%:%BACKEND_PORT% -e SPRING_PROFILES_ACTIVE=prod -e SERVER_PORT=%BACKEND_PORT% -e DB_HOST=mysql -e DB_PORT=3306 -e DB_NAME=%MYSQL_DATABASE% -e DB_USERNAME=%MYSQL_USER% -e DB_PASSWORD=%MYSQL_PASSWORD% -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD= -e REDIS_DATABASE=0 -e JWT_SECRET=%JWT_SECRET% -e JWT_EXPIRATION=%JWT_EXPIRATION% -e CORS_ALLOWED_ORIGINS=%CORS_ALLOWED_ORIGINS% lab-backend

:: 启动前端
echo [启动] 前端服务...
docker run -d --name lab-frontend --restart always --network lab-network -p %FRONTEND_PORT%:80 lab-frontend

:: 可选：启动监控
if /i "%MONITOR_ENABLED%"=="true" (
    echo [监控] 部署监控服务...
    docker stop lab-prometheus lab-grafana lab-alertmanager lab-loki lab-promtail lab-node-exporter lab-cadvisor lab-mysql-exporter lab-redis-exporter lab-blackbox-exporter 2>nul
    docker rm lab-prometheus lab-grafana lab-alertmanager lab-loki lab-promtail lab-node-exporter lab-cadvisor lab-mysql-exporter lab-redis-exporter lab-blackbox-exporter 2>nul
    cd /d "%PROJECT_ROOT%\monitor"
    docker-compose -f docker-compose.monitoring.yml up -d
    echo [监控] Grafana: http://localhost:3001 (admin/admin123)
    echo [监控] Prometheus: http://localhost:9090
) else (
    echo [监控] 未启用 (设 MONITOR_ENABLED=true 可自动部署)
)

:: 等待后端就绪
echo [等待] 服务启动中...
timeout /t 30 /nobreak >nul

echo [检查] 健康检查...
curl -s http://localhost:%BACKEND_PORT%/api/actuator/health 2>nul

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                      部署完成！                            ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  前端页面: http://localhost:%FRONTEND_PORT%                       ║
echo ║  后端API:  http://localhost:%BACKEND_PORT%/api                      ║
echo ║  默认账号: admin / admin123                               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 查看日志: docker logs -f lab-backend
echo.
pause
