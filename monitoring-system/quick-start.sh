#!/bin/bash

# ============================================
# 快速启动脚本 - 一键部署监控系统
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示Banner
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          通用监控系统 - 快速启动                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="${SCRIPT_DIR}/monitoring"

# 检查Docker
echo -e "${GREEN}[1/4]${NC} 检查Docker环境..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    echo "请先安装Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker未运行${NC}"
    echo "请先启动Docker"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker环境正常"

# 创建目录结构
echo -e "${GREEN}[2/4]${NC} 创建目录结构..."
mkdir -p "${MONITORING_DIR}"/{prometheus,alertmanager,grafana/provisioning/{datasources,dashboards},loki/rules,promtail,blackbox,config,data,logs}

# 生成配置文件（如果不存在）
if [ ! -f "${MONITORING_DIR}/docker-compose.yml" ]; then
    echo -e "${GREEN}[3/4]${NC} 生成配置文件..."
    
    # 项目配置
    cat > "${MONITORING_DIR}/config/project.conf" << 'EOF'
PROJECT_NAME=lab-management
ENVIRONMENT=production
BACKEND_HOST=host.docker.internal
BACKEND_PORT=8081
FRONTEND_HOST=host.docker.internal
FRONTEND_PORT=3000
GRAFANA_PORT=3001
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin123
PROMETHEUS_PORT=9090
LOKI_PORT=3100
PROMETHEUS_RETENTION=15d
EOF

    # Prometheus配置
    cat > "${MONITORING_DIR}/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  - job_name: 'backend'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['host.docker.internal:8081']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

    # 告警规则
    cat > "${MONITORING_DIR}/prometheus/alert_rules.yml" << 'EOF'
groups:
  - name: service_alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "服务已停止"
EOF

    # Alertmanager配置
    cat > "${MONITORING_DIR}/alertmanager/alertmanager.yml" << 'EOF'
global:
  resolve_timeout: 5m

route:
  receiver: 'default-receiver'

receivers:
  - name: 'default-receiver'
EOF

    # Loki配置
    cat > "${MONITORING_DIR}/loki/loki-config.yml" << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF

    # Promtail配置
    cat > "${MONITORING_DIR}/promtail/promtail-config.yml" << 'EOF'
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: application-logs
    static_configs:
      - targets: [localhost]
        labels:
          job: application
          __path__: /var/log/application/*.log
EOF

    # Grafana数据源
    cat > "${MONITORING_DIR}/grafana/provisioning/datasources/datasources.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
EOF

    # Dashboard配置
    cat > "${MONITORING_DIR}/grafana/provisioning/dashboards/dashboards.yml" << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    # Docker Compose
    cat > "${MONITORING_DIR}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: monitoring-prometheus
    restart: unless-stopped
    ports: ["9090:9090"]
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - ./data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    networks: [monitoring]

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: monitoring-alertmanager
    restart: unless-stopped
    ports: ["9093:9093"]
    volumes:
      - ./alertmanager:/etc/alertmanager:ro
    networks: [monitoring]

  grafana:
    image: grafana/grafana:10.0.0
    container_name: monitoring-grafana
    restart: unless-stopped
    ports: ["3001:3000"]
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./data/grafana:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    networks: [monitoring]
    depends_on: [prometheus, loki]

  loki:
    image: grafana/loki:2.9.0
    container_name: monitoring-loki
    restart: unless-stopped
    ports: ["3100:3100"]
    volumes:
      - ./loki:/etc/loki:ro
      - ./data/loki:/loki
    command: -config.file=/etc/loki/loki-config.yml
    networks: [monitoring]

  promtail:
    image: grafana/promtail:2.9.0
    container_name: monitoring-promtail
    restart: unless-stopped
    volumes:
      - ./promtail:/etc/promtail:ro
      - ./logs:/var/log/application:ro
    command: -config.file=/etc/promtail/promtail-config.yml
    networks: [monitoring]
    depends_on: [loki]

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: monitoring-cadvisor
    restart: unless-stopped
    ports: ["8080:8080"]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
    networks: [monitoring]

networks:
  monitoring:
    driver: bridge
EOF

    echo -e "${GREEN}✓${NC} 配置文件生成完成"
else
    echo -e "${GREEN}[3/4]${NC} 配置文件已存在，跳过生成"
fi

# 启动服务
echo -e "${GREEN}[4/4]${NC} 启动监控服务..."
cd "${MONITORING_DIR}"
docker-compose up -d

echo ""
sleep 5

# 检查状态
echo -e "${CYAN}服务状态:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              监控系统启动成功！                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}访问地址:${NC}"
echo "  Prometheus:   http://localhost:9090"
echo "  Grafana:      http://localhost:3001 (admin/admin123)"
echo "  Loki:         http://localhost:3100"
echo "  Alertmanager: http://localhost:9093"
echo "  cAdvisor:     http://localhost:8080"
echo ""
echo -e "${YELLOW}提示: 要停止监控系统，运行: cd monitoring && docker-compose down${NC}"
echo ""
