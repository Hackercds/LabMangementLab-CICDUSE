#!/bin/bash

# ============================================
# 通用监控系统 - 一键部署脚本
# 支持: Prometheus + Grafana + Loki + Alertmanager
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="${SCRIPT_DIR}/monitoring"

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 显示Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          通用监控系统 - 一键部署工具 v1.0.0               ║"
    echo "║     Prometheus + Grafana + Loki + Alertmanager             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        missing+=("docker-compose")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少以下依赖: ${missing[*]}"
        echo ""
        echo "安装方法:"
        echo "  Docker:         curl -fsSL https://get.docker.com | sh"
        echo "  Docker Compose: sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker未运行，请先启动Docker"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 初始化监控系统
init_monitoring() {
    log_step "初始化监控系统..."
    
    # 创建目录结构
    mkdir -p "${MONITORING_DIR}"/{prometheus,alertmanager,grafana/provisioning/{datasources,dashboards},loki/rules,promtail,blackbox,config}
    
    # 创建数据目录
    mkdir -p "${MONITORING_DIR}"/data/{prometheus,grafana,loki,alertmanager}
    
    # 创建日志目录
    mkdir -p "${MONITORING_DIR}"/logs
    
    log_success "目录结构创建完成"
}

# 生成配置文件
generate_configs() {
    log_step "生成配置文件..."
    
    # 生成项目配置
    if [ ! -f "${MONITORING_DIR}/config/project.conf" ]; then
        cat > "${MONITORING_DIR}/config/project.conf" << 'EOF'
# ============================================
# 项目配置文件
# ============================================

# 项目名称
PROJECT_NAME=${PROJECT_NAME:-"my-project"}

# 环境
ENVIRONMENT=${ENVIRONMENT:-"production"}

# 后端服务地址 (用于监控)
BACKEND_HOST=${BACKEND_HOST:-"host.docker.internal"}
BACKEND_PORT=${BACKEND_PORT:-"8080"}

# 前端服务地址
FRONTEND_HOST=${FRONTEND_HOST:-"host.docker.internal"}
FRONTEND_PORT=${FRONTEND_PORT:-"3000"}

# 数据库配置
MYSQL_HOST=${MYSQL_HOST:-"mysql"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_USER=${MYSQL_USER:-"root"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"root123456"}

# Redis配置
REDIS_HOST=${REDIS_HOST:-"redis"}
REDIS_PORT=${REDIS_PORT:-"6379"}

# 告警配置
ALERT_EMAIL=${ALERT_EMAIL:-"admin@example.com"}
ALERT_WEBHOOK=${ALERT_WEBHOOK:-""}

# Grafana配置
GRAFANA_PORT=${GRAFANA_PORT:-"3001"}
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER:-"admin"}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"admin123"}

# Prometheus配置
PROMETHEUS_PORT=${PROMETHEUS_PORT:-"9090"}
PROMETHEUS_RETENTION=${PROMETHEUS_RETENTION:-"15d"}

# Loki配置
LOKI_PORT=${LOKI_PORT:-"3100"}
LOKI_RETENTION=${LOKI_RETENTION:-"744h"}
EOF
        log_info "已创建项目配置文件: ${MONITORING_DIR}/config/project.conf"
    fi
    
    # 生成Prometheus配置
    cat > "${MONITORING_DIR}/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: '${PROJECT_NAME}-monitor'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

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
      - targets: ['${BACKEND_HOST}:${BACKEND_PORT}']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'backend'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://${BACKEND_HOST}:${BACKEND_PORT}/actuator/health
        - http://${FRONTEND_HOST}:${FRONTEND_PORT}
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
EOF

    # 生成告警规则
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
          summary: "服务 {{ $labels.job }} 已停止"
          description: "服务 {{ $labels.instance }} 已经停止超过1分钟"

      - alert: HighErrorRate
        expr: sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "HTTP错误率过高"
          description: "HTTP 5xx错误率超过5%"

  - name: system_alerts
    rules:
      - alert: HighCpuUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU使用率过高"
          description: "CPU使用率超过80%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "内存使用率过高"
          description: "内存使用率超过85%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "磁盘空间不足"
          description: "磁盘剩余空间不足15%"
EOF

    # 生成Alertmanager配置
    cat > "${MONITORING_DIR}/alertmanager/alertmanager.yml" << 'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-receiver'

receivers:
  - name: 'default-receiver'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF

    # 生成Loki配置
    cat > "${MONITORING_DIR}/loki/loki-config.yml" << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

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

limits_config:
  retention_period: 744h
  ingestion_rate_mb: 20

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  retention_enabled: true
EOF

    # 生成Promtail配置
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
      - targets:
          - localhost
        labels:
          job: application
          __path__: /var/log/application/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\s+(?P<level>\w+)\s+(?P<message>.*)$'
      - labels:
          level:
EOF

    # 生成Blackbox配置
    cat > "${MONITORING_DIR}/blackbox/blackbox.yml" << 'EOF'
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200, 201, 202, 204]
      method: GET
EOF

    # 生成Grafana数据源配置
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

  - name: Alertmanager
    type: alertmanager
    access: proxy
    url: http://alertmanager:9093
EOF

    # 生成Dashboard配置
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

    log_success "配置文件生成完成"
}

# 生成Docker Compose文件
generate_docker_compose() {
    log_step "生成Docker Compose文件..."
    
    cat > "${MONITORING_DIR}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: ${PROJECT_NAME}-prometheus
    restart: unless-stopped
    ports:
      - "${PROMETHEUS_PORT}:9090"
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - ./data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${PROMETHEUS_RETENTION}'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: ${PROJECT_NAME}-alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager:ro
      - ./data/alertmanager:/alertmanager
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.0.0
    container_name: ${PROJECT_NAME}-grafana
    restart: unless-stopped
    ports:
      - "${GRAFANA_PORT}:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./data/grafana:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel
    networks:
      - monitoring
    depends_on:
      - prometheus
      - loki

  loki:
    image: grafana/loki:2.9.0
    container_name: ${PROJECT_NAME}-loki
    restart: unless-stopped
    ports:
      - "${LOKI_PORT}:3100"
    volumes:
      - ./loki:/etc/loki:ro
      - ./data/loki:/loki
    command: -config.file=/etc/loki/loki-config.yml
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:2.9.0
    container_name: ${PROJECT_NAME}-promtail
    restart: unless-stopped
    volumes:
      - ./promtail:/etc/promtail:ro
      - /var/log:/var/log:ro
      - ./logs:/var/log/application:ro
    command: -config.file=/etc/promtail/promtail-config.yml
    networks:
      - monitoring
    depends_on:
      - loki

  node-exporter:
    image: prom/node-exporter:v1.6.0
    container_name: ${PROJECT_NAME}-node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: ${PROJECT_NAME}-cadvisor
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    networks:
      - monitoring

  blackbox-exporter:
    image: prom/blackbox-exporter:v0.24.0
    container_name: ${PROJECT_NAME}-blackbox
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox:/etc/blackbox_exporter:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
EOF

    log_success "Docker Compose文件生成完成"
}

# 启动监控系统
start_monitoring() {
    log_step "启动监控系统..."
    
    cd "${MONITORING_DIR}"
    
    # 加载环境变量
    if [ -f "config/project.conf" ]; then
        export $(grep -v '^#' config/project.conf | xargs)
    fi
    
    # 启动服务
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    docker-compose ps
    
    echo ""
    log_success "=========================================="
    log_success "监控系统启动成功！"
    log_success "=========================================="
    echo ""
    echo "访问地址:"
    echo "  Prometheus:   http://localhost:${PROMETHEUS_PORT:-9090}"
    echo "  Grafana:      http://localhost:${GRAFANA_PORT:-3001} (${GRAFANA_ADMIN_USER:-admin}/${GRAFANA_ADMIN_PASSWORD:-admin123})"
    echo "  Loki:         http://localhost:${LOKI_PORT:-3100}"
    echo "  Alertmanager: http://localhost:9093"
    echo "  cAdvisor:     http://localhost:8080"
    echo ""
}

# 停止监控系统
stop_monitoring() {
    log_step "停止监控系统..."
    
    cd "${MONITORING_DIR}"
    docker-compose down
    
    log_success "监控系统已停止"
}

# 查看状态
show_status() {
    log_info "监控系统状态:"
    cd "${MONITORING_DIR}"
    docker-compose ps
}

# 查看日志
show_logs() {
    local service=$1
    cd "${MONITORING_DIR}"
    
    if [ -z "$service" ]; then
        docker-compose logs -f --tail=100
    else
        docker-compose logs -f --tail=100 "$service"
    fi
}

# 配置向导
config_wizard() {
    log_step "配置向导"
    echo ""
    
    read -p "项目名称 [my-project]: " project_name
    project_name=${project_name:-my-project}
    
    read -p "后端服务地址 [host.docker.internal]: " backend_host
    backend_host=${backend_host:-host.docker.internal}
    
    read -p "后端服务端口 [8080]: " backend_port
    backend_port=${backend_port:-8080}
    
    read -p "前端服务端口 [3000]: " frontend_port
    frontend_port=${frontend_port:-3000}
    
    read -p "Grafana端口 [3001]: " grafana_port
    grafana_port=${grafana_port:-3001}
    
    read -p "Grafana管理员密码 [admin123]: " grafana_password
    grafana_password=${grafana_password:-admin123}
    
    # 更新配置文件
    cat > "${MONITORING_DIR}/config/project.conf" << EOF
PROJECT_NAME=${project_name}
ENVIRONMENT=production
BACKEND_HOST=${backend_host}
BACKEND_PORT=${backend_port}
FRONTEND_HOST=${backend_host}
FRONTEND_PORT=${frontend_port}
GRAFANA_PORT=${grafana_port}
GRAFANA_ADMIN_PASSWORD=${grafana_password}
PROMETHEUS_PORT=9090
LOKI_PORT=3100
PROMETHEUS_RETENTION=15d
EOF
    
    log_success "配置已保存"
}

# 显示帮助
show_help() {
    show_banner
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  init        初始化监控系统"
    echo "  start       启动监控系统"
    echo "  stop        停止监控系统"
    echo "  restart     重启监控系统"
    echo "  status      查看服务状态"
    echo "  logs [服务] 查看日志"
    echo "  config      配置向导"
    echo "  help        显示帮助信息"
    echo ""
    echo "快速开始:"
    echo "  $0 init && $0 start    # 初始化并启动"
    echo ""
    echo "配置文件: ${MONITORING_DIR}/config/project.conf"
}

# 主函数
main() {
    show_banner
    
    local command=${1:-help}
    
    case $command in
        init)
            check_dependencies
            init_monitoring
            generate_configs
            generate_docker_compose
            config_wizard
            ;;
        start)
            check_dependencies
            if [ ! -d "${MONITORING_DIR}" ]; then
                log_error "请先运行: $0 init"
                exit 1
            fi
            start_monitoring
            ;;
        stop)
            stop_monitoring
            ;;
        restart)
            stop_monitoring
            sleep 3
            start_monitoring
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        config)
            config_wizard
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
