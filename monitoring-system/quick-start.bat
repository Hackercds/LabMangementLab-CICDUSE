@echo off
chcp 65001 >nul
REM ============================================
REM 快速启动脚本 - 一键部署监控系统
REM ============================================

setlocal enabledelayedexpansion

REM 颜色代码
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "GREEN=!ESC![92m"
set "CYAN=!ESC![96m"
set "YELLOW=!ESC![93m"
set "NC=!ESC![0m"

REM 显示Banner
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║          通用监控系统 - 快速启动                          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM 获取脚本目录
set SCRIPT_DIR=%~dp0
set MONITORING_DIR=%SCRIPT_DIR%monitoring

REM 检查Docker
echo %GREEN%[1/4]%NC% 检查Docker环境...

where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker未安装
    echo 请先安装Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker未运行
    echo 请先启动Docker Desktop
    pause
    exit /b 1
)

echo %GREEN%✓%NC% Docker环境正常

REM 创建目录结构
echo %GREEN%[2/4]%NC% 创建目录结构...

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

REM 生成配置文件
if not exist "%MONITORING_DIR%\docker-compose.yml" (
    echo %GREEN%[3/4]%NC% 生成配置文件...

    REM Prometheus配置
    (
echo global:
echo   scrape_interval: 15s
echo   evaluation_interval: 15s
echo.
echo alerting:
echo   alertmanagers:
echo     - static_configs:
echo         - targets: ['alertmanager:9093']
echo.
echo scrape_configs:
echo   - job_name: 'prometheus'
echo     static_configs:
echo       - targets: ['localhost:9090']
echo.
echo   - job_name: 'backend'
echo     metrics_path: '/actuator/prometheus'
echo     static_configs:
echo       - targets: ['host.docker.internal:8081']
echo.
echo   - job_name: 'loki'
echo     static_configs:
echo       - targets: ['loki:3100']
echo.
echo   - job_name: 'cadvisor'
echo     static_configs:
echo       - targets: ['cadvisor:8080']
    ) > "%MONITORING_DIR%\prometheus\prometheus.yml"

    REM Alertmanager配置
    (
echo global:
echo   resolve_timeout: 5m
echo.
echo route:
echo   receiver: 'default-receiver'
echo.
echo receivers:
echo   - name: 'default-receiver'
    ) > "%MONITORING_DIR%\alertmanager\alertmanager.yml"

    REM Loki配置
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

    REM Promtail配置
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
echo       - targets: [localhost]
echo         labels:
echo           job: application
echo           __path__: /var/log/application/*.log
    ) > "%MONITORING_DIR%\promtail\promtail-config.yml"

    REM Grafana数据源
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

    REM Dashboard配置
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

    REM Docker Compose
    (
echo version: '3.8'
echo.
echo services:
echo   prometheus:
echo     image: prom/prometheus:v2.45.0
echo     container_name: monitoring-prometheus
echo     restart: unless-stopped
echo     ports: ["9090:9090"]
echo     volumes:
echo       - ./prometheus:/etc/prometheus:ro
echo       - ./data/prometheus:/prometheus
echo     networks: [monitoring]
echo.
echo   alertmanager:
echo     image: prom/alertmanager:v0.25.0
echo     container_name: monitoring-alertmanager
echo     restart: unless-stopped
echo     ports: ["9093:9093"]
echo     volumes:
echo       - ./alertmanager:/etc/alertmanager:ro
echo     networks: [monitoring]
echo.
echo   grafana:
echo     image: grafana/grafana:10.0.0
echo     container_name: monitoring-grafana
echo     restart: unless-stopped
echo     ports: ["3001:3000"]
echo     volumes:
echo       - ./grafana/provisioning:/etc/grafana/provisioning:ro
echo       - ./data/grafana:/var/lib/grafana
echo     environment:
echo       - GF_SECURITY_ADMIN_USER=admin
echo       - GF_SECURITY_ADMIN_PASSWORD=admin123
echo     networks: [monitoring]
echo.
echo   loki:
echo     image: grafana/loki:2.9.0
echo     container_name: monitoring-loki
echo     restart: unless-stopped
echo     ports: ["3100:3100"]
echo     volumes:
echo       - ./loki:/etc/loki:ro
echo       - ./data/loki:/loki
echo     command: -config.file=/etc/loki/loki-config.yml
echo     networks: [monitoring]
echo.
echo   promtail:
echo     image: grafana/promtail:2.9.0
echo     container_name: monitoring-promtail
echo     restart: unless-stopped
echo     volumes:
echo       - ./promtail:/etc/promtail:ro
echo       - ./logs:/var/log/application:ro
echo     command: -config.file=/etc/promtail/promtail-config.yml
echo     networks: [monitoring]
echo.
echo   cadvisor:
echo     image: gcr.io/cadvisor/cadvisor:v0.47.0
echo     container_name: monitoring-cadvisor
echo     restart: unless-stopped
echo     ports: ["8080:8080"]
echo     volumes:
echo       - /:/rootfs:ro
echo       - /var/run:/var/run:ro
echo     networks: [monitoring]
echo.
echo networks:
echo   monitoring:
echo     driver: bridge
    ) > "%MONITORING_DIR%\docker-compose.yml"

    echo %GREEN%✓%NC% 配置文件生成完成
) else (
    echo %GREEN%[3/4]%NC% 配置文件已存在，跳过生成
)

REM 启动服务
echo %GREEN%[4/4]%NC% 启动监控服务...

cd /d "%MONITORING_DIR%"
docker-compose up -d

echo.
timeout /t 5 /nobreak >nul

REM 检查状态
echo %CYAN%服务状态:%NC%
docker-compose ps

echo.
echo %GREEN%╔════════════════════════════════════════════════════════════╗%NC%
echo %GREEN%║              监控系统启动成功！                            ║%NC%
echo %GREEN%╚════════════════════════════════════════════════════════════╝%NC%
echo.
echo %CYAN%访问地址:%NC%
echo   Prometheus:   http://localhost:9090
echo   Grafana:      http://localhost:3001 (admin/admin123)
echo   Loki:         http://localhost:3100
echo   Alertmanager: http://localhost:9093
echo   cAdvisor:     http://localhost:8080
echo.
echo %YELLOW%提示: 要停止监控系统，运行: cd monitoring ^&^& docker-compose down%NC%
echo.

pause
