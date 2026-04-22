#!/bin/bash

# 实验室管理系统 - 一键重启脚本
# 支持 Java/Python/Golang 前后端服务

set -e

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/deploy.conf"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 重启服务
restart_service() {
    local service_name=$1
    local start_cmd=$2
    local stop_cmd=$3
    local delay=${4:-3}
    
    log_step "重启服务: $service_name"
    
    # 停止服务
    log_info "停止服务..."
    $stop_cmd
    
    # 等待
    log_info "等待 ${delay} 秒..."
    sleep $delay
    
    # 启动服务
    log_info "启动服务..."
    $start_cmd
    
    log_info "服务 $service_name 重启完成"
}

# 重启Java后端
restart_java_backend() {
    log_info "=========================================="
    log_info "重启Java后端服务"
    log_info "=========================================="
    
    "${SCRIPT_DIR}/stop.sh" backend
    sleep 3
    "${SCRIPT_DIR}/start.sh" backend
}

# 重启Java后端 (开发模式)
restart_java_backend_dev() {
    log_info "=========================================="
    log_info "重启Java后端服务 (开发模式)"
    log_info "=========================================="
    
    "${SCRIPT_DIR}/stop.sh" backend
    sleep 3
    "${SCRIPT_DIR}/start.sh" backend-dev
}

# 重启Python服务
restart_python_service() {
    log_info "=========================================="
    log_info "重启Python服务"
    log_info "=========================================="
    
    "${SCRIPT_DIR}/stop.sh" python
    sleep 3
    "${SCRIPT_DIR}/start.sh" python
}

# 重启Golang服务
restart_golang_service() {
    log_info "=========================================="
    log_info "重启Golang服务"
    log_info "=========================================="
    
    "${SCRIPT_DIR}/stop.sh" golang
    sleep 3
    "${SCRIPT_DIR}/start.sh" golang
}

# 重启前端服务
restart_frontend() {
    log_info "=========================================="
    log_info "重启前端服务"
    log_info "=========================================="
    
    "${SCRIPT_DIR}/stop.sh" frontend
    sleep 3
    "${SCRIPT_DIR}/start.sh" frontend
}

# 重启所有服务
restart_all() {
    log_info "=========================================="
    log_info "重启所有服务"
    log_info "=========================================="
    
    local start_time=$(date +%s)
    
    # 停止所有服务
    log_step "停止所有服务..."
    "${SCRIPT_DIR}/stop.sh" all
    
    log_info "等待5秒..."
    sleep 5
    
    # 启动所有服务
    log_step "启动所有服务..."
    "${SCRIPT_DIR}/start.sh" all
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    log_info "=========================================="
    log_info "所有服务重启完成！耗时: ${duration}秒"
    log_info "=========================================="
}

# 优雅重启 (逐个服务重启，保证服务可用性)
graceful_restart() {
    log_info "=========================================="
    log_info "优雅重启所有服务"
    log_info "=========================================="
    
    # 先重启后端
    if [ "$JAVA_ENABLED" = true ]; then
        restart_java_backend
        sleep 5
    fi
    
    # 重启Python服务
    if [ "$PYTHON_ENABLED" = true ]; then
        restart_python_service
        sleep 3
    fi
    
    # 重启Golang服务
    if [ "$GOLANG_ENABLED" = true ]; then
        restart_golang_service
        sleep 3
    fi
    
    # 最后重启前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        restart_frontend
    fi
    
    echo ""
    log_info "=========================================="
    log_info "优雅重启完成"
    log_info "=========================================="
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         重启所有服务"
    echo "  backend     重启Java后端服务"
    echo "  backend-dev 重启Java后端服务 (开发模式)"
    echo "  frontend    重启前端服务"
    echo "  python      重启Python服务"
    echo "  golang      重启Golang服务"
    echo "  graceful    优雅重启所有服务 (逐个重启)"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all          # 重启所有服务"
    echo "  $0 backend      # 重启Java后端"
    echo "  $0 graceful     # 优雅重启所有服务"
}

# 主函数
main() {
    local action=${1:-all}
    
    case $action in
        all)
            restart_all
            ;;
        backend)
            restart_java_backend
            ;;
        backend-dev)
            restart_java_backend_dev
            ;;
        frontend)
            restart_frontend
            ;;
        python)
            restart_python_service
            ;;
        golang)
            restart_golang_service
            ;;
        graceful)
            graceful_restart
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $action"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
