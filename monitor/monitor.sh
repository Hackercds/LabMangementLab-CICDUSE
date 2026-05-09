#!/bin/bash

# 实验室管理系统 - 监控服务启动脚本
# 启动 Prometheus + Grafana 监控系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 检查Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
}

# 启动监控服务
start_monitoring() {
    log_step "启动监控服务..."
    
    cd "${SCRIPT_DIR}"
    
    # 创建必要目录
    mkdir -p prometheus alertmanager grafana/provisioning/datasources grafana/provisioning/dashboards blackbox
    
    # 启动服务
    docker-compose -f docker-compose.monitoring.yml up -d
    
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    log_info "服务状态:"
    docker-compose -f docker-compose.monitoring.yml ps
    
    echo ""
    log_info "=========================================="
    log_info "监控服务已启动"
    log_info "=========================================="
    echo ""
    log_info "访问地址:"
    log_info "  Prometheus:  http://localhost:9090"
    log_info "  Grafana:     http://localhost:3001 (admin/admin123)"
    log_info "  Alertmanager: http://localhost:9093"
    log_info "  cAdvisor:    http://localhost:8080"
    echo ""
}

# 停止监控服务
stop_monitoring() {
    log_step "停止监控服务..."
    
    cd "${SCRIPT_DIR}"
    docker-compose -f docker-compose.monitoring.yml down
    
    log_info "监控服务已停止"
}

# 重启监控服务
restart_monitoring() {
    stop_monitoring
    sleep 3
    start_monitoring
}

# 查看监控服务状态
status_monitoring() {
    log_info "监控服务状态:"
    cd "${SCRIPT_DIR}"
    docker-compose -f docker-compose.monitoring.yml ps
}

# 查看监控服务日志
logs_monitoring() {
    local service=$1
    cd "${SCRIPT_DIR}"
    
    if [ -z "$service" ]; then
        docker-compose -f docker-compose.monitoring.yml logs -f --tail=100
    else
        docker-compose -f docker-compose.monitoring.yml logs -f --tail=100 "$service"
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 <命令>"
    echo ""
    echo "命令:"
    echo "  start     启动监控服务"
    echo "  stop      停止监控服务"
    echo "  restart   重启监控服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start           # 启动监控服务"
    echo "  $0 logs prometheus # 查看Prometheus日志"
}

# 主函数
main() {
    local command=${1:-help}
    
    check_docker
    
    case $command in
        start)
            start_monitoring
            ;;
        stop)
            stop_monitoring
            ;;
        restart)
            restart_monitoring
            ;;
        status)
            status_monitoring
            ;;
        logs)
            logs_monitoring "$2"
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
