#!/bin/bash

# 实验室管理系统 - 一键停止脚本
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

# 停止服务
stop_service() {
    local service_name=$1
    local port=$2
    
    log_step "停止服务: $service_name"
    
    local pid_file="${PID_DIR}/${service_name}.pid"
    local stopped=false
    
    # 方法1: 通过PID文件停止
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        
        if ps -p $pid > /dev/null 2>&1; then
            log_info "发送SIGTERM信号到进程 $pid..."
            kill $pid 2>/dev/null || true
            
            # 等待进程结束
            local wait_time=0
            local max_wait=30
            
            while ps -p $pid > /dev/null 2>&1; do
                if [ $wait_time -ge $max_wait ]; then
                    log_warn "进程未响应，发送SIGKILL信号..."
                    kill -9 $pid 2>/dev/null || true
                    break
                fi
                sleep 1
                wait_time=$((wait_time + 1))
            done
            
            log_info "服务 $service_name 已停止 (PID: $pid)"
            stopped=true
        else
            log_warn "进程不存在 (PID: $pid)"
        fi
        
        rm -f "$pid_file"
    fi
    
    # 方法2: 通过端口停止
    if [ -n "$port" ]; then
        local port_pids=$(lsof -ti :$port 2>/dev/null || true)
        
        if [ -n "$port_pids" ]; then
            for pid in $port_pids; do
                if ps -p $pid > /dev/null 2>&1; then
                    log_info "通过端口 $port 停止进程 $pid..."
                    kill $pid 2>/dev/null || true
                    
                    sleep 2
                    
                    if ps -p $pid > /dev/null 2>&1; then
                        kill -9 $pid 2>/dev/null || true
                    fi
                    
                    log_info "进程 $pid 已停止"
                    stopped=true
                fi
            done
        fi
    fi
    
    # 方法3: 通过进程名停止
    local process_names=()
    case $service_name in
        backend|java*)
            process_names=("java" "spring-boot")
            ;;
        frontend|node*)
            process_names=("node" "vite")
            ;;
        python*)
            process_names=("python" "python3" "gunicorn" "uvicorn")
            ;;
        golang*)
            process_names=("${GOLANG_SERVICE_NAME}")
            ;;
    esac
    
    for proc_name in "${process_names[@]}"; do
        local pids=$(pgrep -f "$proc_name" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                if [ -n "$port" ]; then
                    local pid_port=$(lsof -p $pid -a -i :$port -t 2>/dev/null || true)
                    if [ -z "$pid_port" ]; then
                        continue
                    fi
                fi
                
                if ps -p $pid > /dev/null 2>&1; then
                    log_info "通过进程名停止进程 $pid..."
                    kill $pid 2>/dev/null || true
                    stopped=true
                fi
            done
        fi
    done
    
    if [ "$stopped" = false ]; then
        log_warn "服务 $service_name 未运行"
    fi
    
    return 0
}

# 停止Java后端
stop_java_backend() {
    stop_service "${JAVA_SERVICE_NAME}" "${JAVA_PORT}"
}

# 停止Python服务
stop_python_service() {
    stop_service "${PYTHON_SERVICE_NAME}" "${PYTHON_PORT}"
}

# 停止Golang服务
stop_golang_service() {
    stop_service "${GOLANG_SERVICE_NAME}" "${GOLANG_PORT}"
}

# 停止前端服务
stop_frontend() {
    stop_service "${FRONTEND_SERVICE_NAME}" "${FRONTEND_PORT}"
}

# 停止所有服务
stop_all() {
    log_info "=========================================="
    log_info "停止所有服务"
    log_info "=========================================="
    
    # 停止前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        stop_frontend
    fi
    
    # 停止Golang服务
    if [ "$GOLANG_ENABLED" = true ]; then
        stop_golang_service
    fi
    
    # 停止Python服务
    if [ "$PYTHON_ENABLED" = true ]; then
        stop_python_service
    fi
    
    # 停止Java后端
    if [ "$JAVA_ENABLED" = true ]; then
        stop_java_backend
    fi
    
    echo ""
    log_info "=========================================="
    log_info "所有服务已停止"
    log_info "=========================================="
}

# 强制停止所有服务
force_stop_all() {
    log_warn "强制停止所有服务..."
    
    # 查找所有相关进程
    local patterns=(
        "spring-boot"
        "lab-management"
        "vite"
        "node.*frontend"
        "python.*app.py"
        "gunicorn"
        "uvicorn"
    )
    
    for pattern in "${patterns[@]}"; do
        local pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                log_info "强制停止进程 $pid..."
                kill -9 $pid 2>/dev/null || true
            done
        fi
    done
    
    # 清理PID文件
    rm -f "${PID_DIR}"/*.pid
    
    log_info "强制停止完成"
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         停止所有服务"
    echo "  backend     停止Java后端服务"
    echo "  frontend    停止前端服务"
    echo "  python      停止Python服务"
    echo "  golang      停止Golang服务"
    echo "  force       强制停止所有服务"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all          # 停止所有服务"
    echo "  $0 backend      # 停止Java后端"
    echo "  $0 frontend     # 停止前端"
    echo "  $0 force        # 强制停止所有服务"
}

# 主函数
main() {
    local action=${1:-all}
    
    case $action in
        all)
            stop_all
            ;;
        backend)
            stop_java_backend
            ;;
        frontend)
            stop_frontend
            ;;
        python)
            stop_python_service
            ;;
        golang)
            stop_golang_service
            ;;
        force)
            force_stop_all
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
