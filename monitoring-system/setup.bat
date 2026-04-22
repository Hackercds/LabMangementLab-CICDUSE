@echo off
chcp 65001 >nul
REM ============================================
REM 通用监控系统 - Windows一键部署脚本
REM 支持: Prometheus + Grafana + Loki + Alertmanager
REM ============================================

setlocal enabledelayedexpansion

REM 颜色代码
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=!ESC![91m"
set "GREEN=!ESC![92m"
set "YELLOW=!ESC![93m"
set "CYAN=!ESC![96m"
set "NC=!ESC![0m"

REM 获取脚本目录
set SCRIPT_DIR=%~dp0
set MONITORING_DIR=%SCRIPT_DIR%monitoring

REM 日志函数
:log_info
echo %GREEN%[INFO]%NC% %~1
goto :eof

:log_warn
echo %YELLOW%[WARN]%NC% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %~1
goto :eof

:log_step
echo %CYAN%[STEP]%NC% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

REM 显示Banner
:show_banner
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║          通用监控系统 - 一键部署工具 v1.0.0               ║
echo ║     Prometheus + Grafana + Loki + Alertmanager             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
goto :eof

REM 检查依赖
:check_dependencies
call :log_step "检查系统依赖..."

where docker >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Docker未安装，请先安装Docker Desktop"
    echo 下载地址: https://www.docker.com/products/docker-desktop
    exit /b 1
)

where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Docker Compose未安装"
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Docker未运行，请先启动Docker Desktop"
    exit /b 1
)

call :log_success "依赖检查通过"
exit /b 0

REM 初始化监控系统
:init_monitoring
call :log_step "初始化监控系统..."

REM 创建目录结构
if not exist "%MONITORING_DIR%" mkdir "%MONITORING_DIR%"
if not exist "%MONITORING_DIR%\prometheus" mkdir "%MONITORING_DIR%\prometheus"
if not exist "%MONITORING_DIR%\alertmanager" mkdir "%MONITORING_DIR%\alertmanager"
if not exist "%MONITORING_DIR%\grafana\provisioning\datasources" mkdir "%MONITORING_DIR%\grafana\provisioning\datasources"
if not exist "%MONITORING_DIR%\grafana\provisioning\dashboards" mkdir "%MONITORING_DIR%\grafana\provisioning\dashboards"
if not exist "%MONITORING_DIR%\loki\rules" mkdir "%MONITORING_DIR%\loki\rules"
if not exist "%MONITORING_DIR%\promtail" mkdir "%MONITORING_DIR%\promtail"
if not exist "%MONITORING_DIR%\blackbox" mkdir "%MONITORING_DIR%\blackbox"
if not exist "%MONITORING_DIR%\config" mkdir "%MONITORING_DIR%\config"
if not exist "%MONITORING_DIR%\data" mkdir "%MONITORING_DIR%\data"
if not exist "%MONITORING_DIR%\logs" mkdir "%MONITORING_DIR%\logs"

call :log_success "目录结构创建完成"
exit /b 0

REM 生成配置文件
:generate_configs
call :log_step "生成配置文件..."

REM 生成项目配置
if not exist "%MONITORING_DIR%\config\project.conf" (
    (
        echo # 项目配置文件
        echo PROJECT_NAME=my-project
        echo ENVIRONMENT=production
        echo BACKEND_HOST=host.docker.internal
        echo BACKEND_PORT=8080
        echo FRONTEND_HOST=host.docker.internal
        echo FRONTEND_PORT=3000
        echo GRAFANA_PORT=3001
        echo GRAFANA_ADMIN_USER=admin
        echo GRAFANA_ADMIN_PASSWORD=admin123
        echo PROMETHEUS_PORT=9090
        echo LOKI_PORT=3100
        echo PROMETHEUS_RETENTION=15d
    ) > "%MONITORING_DIR%\config\project.conf"
    call :log_info "已创建项目配置文件"
)

REM 生成Prometheus配置
(
echo global:
echo   scrape_interval: 15s
echo   evaluation_interval: 15s
echo.
echo alerting:
echo   alertmanagers:
echo     - static_configs:
echo         - targets:
echo           - alertmanager:9093
echo.
echo rule_files:
echo   - /etc/prometheus/alert_rules.yml
echo.
echo scrape_configs:
echo   - job_name: 'prometheus'
echo     static_configs:
echo       - targets: ['localhost:9090']
echo.
echo   - job_name: 'loki'
echo     static_configs:
echo       - targets: ['loki:3100']
echo.
echo   - job_name: 'backend'
echo     metrics_path: '/actuator/prometheus'
echo     static_configs:
echo       - targets: ['host.docker.internal:8080']
echo.
echo   - job_name: 'node-exporter'
echo     static_configs:
echo       - targets: ['node-exporter:9100']
echo.
echo   - job_name: 'cadvisor'
echo     static_configs:
echo       - targets: ['cadvisor:8080']
) > "%MONITORING_DIR%\prometheus\prometheus.yml"

REM 生成告警规则
(
echo groups:
echo   - name: service_alerts
echo     rules:
echo       - alert: ServiceDown
echo         expr: up == 0
echo         for: 1m
echo         labels:
echo           severity: critical
echo         annotations:
echo           summary: "服务已停止"
) > "%MONITORING_DIR%\prometheus\alert_rules.yml"

REM 生成Alertmanager配置
(
echo global:
echo   resolve_timeout: 5m
echo.
echo route:
echo   group_by: ['alertname']
echo   group_wait: 30s
echo   receiver: 'default-receiver'
echo.
echo receivers:
echo   - name: 'default-receiver'
) > "%MONITORING_DIR%\alertmanager\alertmanager.yml"

REM 生成Loki配置
(
echo auth_enabled: false
echo.
echo server:
echo   http_listen_port: 3100
echo.
echo common:
echo   path_prefix: /loki
echo   storage:
echo     filesystem:
echo       chunks_directory: /loki/chunks
echo       rules_directory: /loki/rules
echo   replication_factor: 1
echo   ring:
echo     kvstore:
echo       store: inmemory
echo.
echo schema_config:
echo   configs:
echo     - from: 2020-10-24
echo       store: boltdb-shipper
echo       object_store: filesystem
echo       schema: v11
echo       index:
echo         prefix: index_
echo         period: 24h
) > "%MONITORING_DIR%\loki\loki-config.yml"

REM 生成Promtail配置
(
echo server:
echo   http_listen_port: 9080
echo.
echo positions:
echo   filename: /tmp/positions.yaml
echo.
echo clients:
echo   - url: http://loki:3100/loki/api/v1/push
echo.
echo scrape_configs:
echo   - job_name: application-logs
echo     static_configs:
echo       - targets:
echo           - localhost
echo         labels:
echo           job: application
echo           __path__: /var/log/application/*.log
) > "%MONITORING_DIR%\promtail\promtail-config.yml"

REM 生成Blackbox配置
(
echo modules:
echo   http_2xx:
echo     prober: http
echo     timeout: 10s
echo     http:
echo       valid_status_codes: [200, 201, 202, 204]
) > "%MONITORING_DIR%\blackbox\blackbox.yml"

REM 生成Grafana数据源配置
(
echo apiVersion: 1
echo.
echo datasources:
echo   - name: Prometheus
echo     type: prometheus
echo     access: proxy
echo     url: http://prometheus:9090
echo     isDefault: true
echo.
echo   - name: Loki
echo     type: loki
echo     access: proxy
echo     url: http://loki:3100
) > "%MONITORING_DIR%\grafana\provisioning\datasources\datasources.yml"

REM 生成Dashboard配置
(
echo apiVersion: 1
echo.
echo providers:
echo   - name: 'default'
echo     orgId: 1
echo     folder: ''
echo     type: file
echo     options:
echo       path: /etc/grafana/provisioning/dashboards
) > "%MONITORING_DIR%\grafana\provisioning\dashboards\dashboards.yml"

call :log_success "配置文件生成完成"
exit /b 0

REM 生成Docker Compose文件
:generate_docker_compose
call :log_step "生成Docker Compose文件..."

(
echo version: '3.8'
echo.
echo services:
echo   prometheus:
echo     image: prom/prometheus:v2.45.0
echo     container_name: monitoring-prometheus
echo     restart: unless-stopped
echo     ports:
echo       - "9090:9090"
echo     volumes:
echo       - ./prometheus:/etc/prometheus:ro
echo       - ./data/prometheus:/prometheus
echo     command:
echo       - '--config.file=/etc/prometheus/prometheus.yml'
echo       - '--storage.tsdb.path=/prometheus'
echo       - '--web.enable-lifecycle'
echo     networks:
echo       - monitoring
echo.
echo   alertmanager:
echo     image: prom/alertmanager:v0.25.0
echo     container_name: monitoring-alertmanager
echo     restart: unless-stopped
echo     ports:
echo       - "9093:9093"
echo     volumes:
echo       - ./alertmanager:/etc/alertmanager:ro
echo     networks:
echo       - monitoring
echo.
echo   grafana:
echo     image: grafana/grafana:10.0.0
echo     container_name: monitoring-grafana
echo     restart: unless-stopped
echo     ports:
echo       - "3001:3000"
echo     volumes:
echo       - ./grafana/provisioning:/etc/grafana/provisioning:ro
echo       - ./data/grafana:/var/lib/grafana
echo     environment:
echo       - GF_SECURITY_ADMIN_USER=admin
echo       - GF_SECURITY_ADMIN_PASSWORD=admin123
echo       - GF_USERS_ALLOW_SIGN_UP=false
echo     networks:
echo       - monitoring
echo     depends_on:
echo       - prometheus
echo       - loki
echo.
echo   loki:
echo     image: grafana/loki:2.9.0
echo     container_name: monitoring-loki
echo     restart: unless-stopped
echo     ports:
echo       - "3100:3100"
echo     volumes:
echo       - ./loki:/etc/loki:ro
echo       - ./data/loki:/loki
echo     command: -config.file=/etc/loki/loki-config.yml
echo     networks:
echo       - monitoring
echo.
echo   promtail:
echo     image: grafana/promtail:2.9.0
echo     container_name: monitoring-promtail
echo     restart: unless-stopped
echo     volumes:
echo       - ./promtail:/etc/promtail:ro
echo       - ./logs:/var/log/application:ro
echo     command: -config.file=/etc/promtail/promtail-config.yml
echo     networks:
echo       - monitoring
echo     depends_on:
echo       - loki
echo.
echo   cadvisor:
echo     image: gcr.io/cadvisor/cadvisor:v0.47.0
echo     container_name: monitoring-cadvisor
echo     restart: unless-stopped
echo     ports:
echo       - "8080:8080"
echo     volumes:
echo       - /:/rootfs:ro
echo       - /var/run:/var/run:ro
echo       - /sys:/sys:ro
echo     networks:
echo       - monitoring
echo.
echo   blackbox-exporter:
echo     image: prom/blackbox-exporter:v0.24.0
echo     container_name: monitoring-blackbox
echo     restart: unless-stopped
echo     ports:
echo       - "9115:9115"
echo     volumes:
echo       - ./blackbox:/etc/blackbox_exporter:ro
echo     networks:
echo       - monitoring
echo.
echo networks:
echo   monitoring:
echo     driver: bridge
) > "%MONITORING_DIR%\docker-compose.yml"

call :log_success "Docker Compose文件生成完成"
exit /b 0

REM 启动监控系统
:start_monitoring
call :log_step "启动监控系统..."

cd /d "%MONITORING_DIR%"
docker-compose up -d

call :log_info "等待服务启动..."
timeout /t 10 /nobreak >nul

docker-compose ps

echo.
call :log_success "=========================================="
call :log_success "监控系统启动成功！"
call :log_success "=========================================="
echo.
echo 访问地址:
echo   Prometheus:   http://localhost:9090
echo   Grafana:      http://localhost:3001 (admin/admin123)
echo   Loki:         http://localhost:3100
echo   Alertmanager: http://localhost:9093
echo   cAdvisor:     http://localhost:8080
echo.

exit /b 0

REM 停止监控系统
:stop_monitoring
call :log_step "停止监控系统..."

cd /d "%MONITORING_DIR%"
docker-compose down

call :log_success "监控系统已停止"
exit /b 0

REM 查看状态
:show_status
call :log_info "监控系统状态:"
cd /d "%MONITORING_DIR%"
docker-compose ps
exit /b 0

REM 显示帮助
:show_help
call :show_banner
echo 用法: %~nx0 ^<命令^>
echo.
echo 命令:
echo   init        初始化监控系统
echo   start       启动监控系统
echo   stop        停止监控系统
echo   restart     重启监控系统
echo   status      查看服务状态
echo   help        显示帮助信息
echo.
echo 快速开始:
echo   %~nx0 init ^&^& %~nx0 start
echo.
echo 配置文件: %MONITORING_DIR%\config\project.conf
goto :eof

REM 主函数
call :show_banner

set command=%1
if "%command%"=="" set command=help

if "%command%"=="init" (
    call :check_dependencies
    if %errorlevel% neq 0 exit /b 1
    call :init_monitoring
    call :generate_configs
    call :generate_docker_compose
    exit /b 0
)
if "%command%"=="start" (
    call :check_dependencies
    if %errorlevel% neq 0 exit /b 1
    if not exist "%MONITORING_DIR%" (
        call :log_error "请先运行: %~nx0 init"
        exit /b 1
    )
    call :start_monitoring
    exit /b 0
)
if "%command%"=="stop" (
    call :stop_monitoring
    exit /b 0
)
if "%command%"=="restart" (
    call :stop_monitoring
    timeout /t 3 /nobreak >nul
    call :start_monitoring
    exit /b 0
)
if "%command%"=="status" (
    call :show_status
    exit /b 0
)
if "%command%"=="help" goto show_help
if "%command%"=="--help" goto show_help
if "%command%"=="-h" goto show_help

call :log_error "未知命令: %command%"
call :show_help
exit /b 1
