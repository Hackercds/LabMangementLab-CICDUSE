#!/bin/bash

# 实验室管理系统 - 统一服务管理脚本
# 支持 Java/Python/Golang 前后端服务

set -e

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/deploy.conf"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

# 检查端口是否监听
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# 检查进程
check_process() {
    local pid_file=$1
    
    if [ ! -f "$pid_file" ]; then
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    if ps -p $pid > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 获取服务状态
get_service_status() {
    local service_name=$1
    local port=$2
    local pid_file="${PID_DIR}/${service_name}.pid"
    
    local status=""
    local pid=""
    local port_status=""
    
    if check_process "$pid_file"; then
        pid=$(cat "$pid_file")
        status="${GREEN}运行中${NC}"
    else
        status="${RED}已停止${NC}"
    fi
    
    if check_port $port; then
        port_status="${GREEN}监听中${NC}"
    else
        port_status="${RED}未监听${NC}"
    fi
    
    echo "$status|$pid|$port_status"
}

# 显示所有服务状态
show_status() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "        服务状态概览"
    echo -e "==========================================${NC}"
    echo ""
    printf "%-20s %-15s %-10s %-15s %s\n" "服务名称" "状态" "PID" "端口状态" "端口"
    echo "------------------------------------------------------------------------"
    
    # Java后端
    if [ "$JAVA_ENABLED" = true ]; then
        local java_status=$(get_service_status "${JAVA_SERVICE_NAME}" "${JAVA_PORT}")
        local java_arr=(${java_status//|/ })
        printf "%-20s " "Java后端"
        echo -e "${java_arr[0]}\t\t${java_arr[1]:--}\t${java_arr[2]}\t\t${JAVA_PORT}"
    fi
    
    # Python服务
    if [ "$PYTHON_ENABLED" = true ]; then
        local python_status=$(get_service_status "${PYTHON_SERVICE_NAME}" "${PYTHON_PORT}")
        local python_arr=(${python_status//|/ })
        printf "%-20s " "Python服务"
        echo -e "${python_arr[0]}\t\t${python_arr[1]:--}\t${python_arr[2]}\t\t${PYTHON_PORT}"
    fi
    
    # Golang服务
    if [ "$GOLANG_ENABLED" = true ]; then
        local golang_status=$(get_service_status "${GOLANG_SERVICE_NAME}" "${GOLANG_PORT}")
        local golang_arr=(${golang_status//|/ })
        printf "%-20s " "Golang服务"
        echo -e "${golang_arr[0]}\t\t${golang_arr[1]:--}\t${golang_arr[2]}\t\t${GOLANG_PORT}"
    fi
    
    # 前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        local frontend_status=$(get_service_status "${FRONTEND_SERVICE_NAME}" "${FRONTEND_PORT}")
        local frontend_arr=(${frontend_status//|/ })
        printf "%-20s " "前端服务"
        echo -e "${frontend_arr[0]}\t\t${frontend_arr[1]:--}\t${frontend_arr[2]}\t\t${FRONTEND_PORT}"
    fi
    
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "        守护进程状态"
    echo -e "==========================================${NC}"
    echo ""
    
    # 守护进程状态
    local daemon_pid_file="${PID_DIR}/daemon.pid"
    if check_process "$daemon_pid_file"; then
        local daemon_pid=$(cat "$daemon_pid_file")
        echo -e "守护进程: ${GREEN}运行中${NC} (PID: $daemon_pid)"
    else
        echo -e "守护进程: ${RED}已停止${NC}"
    fi
    
    echo ""
}

# 查看日志
view_logs() {
    local service_name=$1
    local lines=${2:-100}
    
    local log_file="${LOG_DIR}/${service_name}.log"
    
    if [ ! -f "$log_file" ]; then
        log_error "日志文件不存在: $log_file"
        return 1
    fi
    
    echo -e "${CYAN}查看日志: $log_file (最后 $lines 行)${NC}"
    echo "------------------------------------------------------------------------"
    tail -n $lines -f "$log_file"
}

# 查看所有日志
view_all_logs() {
    echo -e "${CYAN}查看所有服务日志${NC}"
    echo "------------------------------------------------------------------------"
    
    if command -v multitail &> /dev/null; then
        local log_files=()
        [ "$JAVA_ENABLED" = true ] && log_files+=("${LOG_DIR}/${JAVA_SERVICE_NAME}.log")
        [ "$PYTHON_ENABLED" = true ] && log_files+=("${LOG_DIR}/${PYTHON_SERVICE_NAME}.log")
        [ "$GOLANG_ENABLED" = true ] && log_files+=("${LOG_DIR}/${GOLANG_SERVICE_NAME}.log")
        [ "$FRONTEND_ENABLED" = true ] && log_files+=("${LOG_DIR}/${FRONTEND_SERVICE_NAME}.log")
        
        multitail "${log_files[@]}"
    else
        log_warn "未安装 multitail，使用 tail 查看后端日志"
        view_logs "${JAVA_SERVICE_NAME}" 50
    fi
}

# 健康检查
health_check() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "        健康检查"
    echo -e "==========================================${NC}"
    echo ""
    
    local all_healthy=true
    
    # Java后端健康检查
    if [ "$JAVA_ENABLED" = true ]; then
        echo -n "Java后端: "
        if curl -sf --connect-timeout 5 "http://localhost:${JAVA_PORT}/api/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}健康${NC}"
        else
            echo -e "${RED}不健康${NC}"
            all_healthy=false
        fi
    fi
    
    # Python服务健康检查
    if [ "$PYTHON_ENABLED" = true ]; then
        echo -n "Python服务: "
        if curl -sf --connect-timeout 5 "http://localhost:${PYTHON_PORT}/health" > /dev/null 2>&1; then
            echo -e "${GREEN}健康${NC}"
        else
            echo -e "${YELLOW}未知${NC}"
        fi
    fi
    
    # Golang服务健康检查
    if [ "$GOLANG_ENABLED" = true ]; then
        echo -n "Golang服务: "
        if curl -sf --connect-timeout 5 "http://localhost:${GOLANG_PORT}/health" > /dev/null 2>&1; then
            echo -e "${GREEN}健康${NC}"
        else
            echo -e "${YELLOW}未知${NC}"
        fi
    fi
    
    # 前端服务检查
    if [ "$FRONTEND_ENABLED" = true ]; then
        echo -n "前端服务: "
        if curl -sf --connect-timeout 5 "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
            echo -e "${GREEN}正常${NC}"
        else
            echo -e "${RED}异常${NC}"
            all_healthy=false
        fi
    fi
    
    echo ""
    
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}所有服务健康${NC}"
        return 0
    else
        echo -e "${RED}部分服务不健康${NC}"
        return 1
    fi
}

# 初始化项目
init_project() {
    log_step "初始化项目..."
    
    # 创建必要目录
    mkdir -p "${LOG_DIR}"
    mkdir -p "${PID_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${RESTART_COUNT_DIR}"
    
    # 检查Java环境
    if [ "$JAVA_ENABLED" = true ]; then
        log_info "检查Java环境..."
        if ! command -v java &> /dev/null; then
            log_error "请先安装Java环境"
        else
            log_info "Java版本: $(java -version 2>&1 | head -n 1)"
        fi
        
        if ! command -v mvn &> /dev/null; then
            log_error "请先安装Maven"
        else
            log_info "Maven版本: $(mvn -version | head -n 1)"
        fi
    fi
    
    # 检查Node.js环境
    if [ "$FRONTEND_ENABLED" = true ]; then
        log_info "检查Node.js环境..."
        if ! command -v node &> /dev/null; then
            log_error "请先安装Node.js"
        else
            log_info "Node.js版本: $(node -v)"
        fi
        
        if ! command -v npm &> /dev/null; then
            log_error "请先安装npm"
        else
            log_info "npm版本: $(npm -v)"
        fi
    fi
    
    # 检查Python环境
    if [ "$PYTHON_ENABLED" = true ]; then
        log_info "检查Python环境..."
        if command -v python3 &> /dev/null; then
            log_info "Python版本: $(python3 --version)"
        elif command -v python &> /dev/null; then
            log_info "Python版本: $(python --version)"
        else
            log_error "请先安装Python"
        fi
    fi
    
    # 检查Go环境
    if [ "$GOLANG_ENABLED" = true ]; then
        log_info "检查Go环境..."
        if ! command -v go &> /dev/null; then
            log_error "请先安装Go"
        else
            log_info "Go版本: $(go version)"
        fi
    fi
    
    log_info "项目初始化完成"
}

# 构建项目
build_project() {
    log_step "构建项目..."
    
    # 构建Java后端
    if [ "$JAVA_ENABLED" = true ]; then
        log_info "构建Java后端..."
        cd "${JAVA_SOURCE_PATH}"
        mvn clean package -DskipTests -q
        if [ $? -ne 0 ]; then
            log_error "Java后端构建失败"
            return 1
        fi
        log_info "Java后端构建完成"
    fi
    
    # 构建前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        log_info "构建前端..."
        cd "${FRONTEND_SOURCE_PATH}"
        if [ ! -d "node_modules" ]; then
            npm install --silent
        fi
        npm run build
        if [ $? -ne 0 ]; then
            log_error "前端构建失败"
            return 1
        fi
        log_info "前端构建完成"
    fi
    
    # 构建Golang服务
    if [ "$GOLANG_ENABLED" = true ]; then
        log_info "构建Golang服务..."
        cd "${GOLANG_SOURCE_PATH}"
        go build -o "${GOLANG_BINARY_PATH}" .
        if [ $? -ne 0 ]; then
            log_error "Golang服务构建失败"
            return 1
        fi
        log_info "Golang服务构建完成"
    fi
    
    log_info "项目构建完成"
}

# 清理项目
clean_project() {
    log_step "清理项目..."
    
    # 清理Java
    if [ "$JAVA_ENABLED" = true ]; then
        log_info "清理Java..."
        cd "${JAVA_SOURCE_PATH}"
        mvn clean -q
    fi
    
    # 清理前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        log_info "清理前端..."
        cd "${FRONTEND_SOURCE_PATH}"
        rm -rf dist node_modules/.cache
    fi
    
    # 清理日志
    log_info "清理日志..."
    rm -rf "${LOG_DIR}"/*.log
    rm -rf "${PID_DIR}"/*.pid
    rm -rf "${RESTART_COUNT_DIR}"/*.count
    
    log_info "清理完成"
}

# 显示帮助
show_help() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "    实验室管理系统 - 服务管理工具"
    echo -e "==========================================${NC}"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo -e "${YELLOW}服务管理命令:${NC}"
    echo "  start [服务]     启动服务 (all/backend/frontend/python/golang)"
    echo "  stop [服务]      停止服务 (all/backend/frontend/python/golang/force)"
    echo "  restart [服务]   重启服务 (all/backend/frontend/python/golang/graceful)"
    echo "  status           查看所有服务状态"
    echo "  health           健康检查"
    echo ""
    echo -e "${YELLOW}守护进程命令:${NC}"
    echo "  daemon start     启动守护进程 (自动拉起异常退出的服务)"
    echo "  daemon stop      停止守护进程"
    echo "  daemon status    查看守护进程状态"
    echo ""
    echo -e "${YELLOW}日志命令:${NC}"
    echo "  logs [服务]      查看服务日志 (backend/frontend/python/golang/daemon)"
    echo "  logs-all         查看所有服务日志"
    echo ""
    echo -e "${YELLOW}项目命令:${NC}"
    echo "  init             初始化项目环境"
    echo "  build            构建项目"
    echo "  clean            清理项目"
    echo ""
    echo -e "${YELLOW}其他命令:${NC}"
    echo "  help             显示帮助信息"
    echo "  version          显示版本信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 start all              # 启动所有服务"
    echo "  $0 start backend          # 启动Java后端"
    echo "  $0 start backend-dev      # 开发模式启动Java后端"
    echo "  $0 stop all               # 停止所有服务"
    echo "  $0 restart all            # 重启所有服务"
    echo "  $0 daemon start           # 启动守护进程"
    echo "  $0 logs backend           # 查看后端日志"
    echo ""
}

# 显示版本
show_version() {
    echo "实验室管理系统 - 服务管理工具 v1.0.0"
    echo "支持: Java / Python / Golang / Node.js"
}

# 主函数
main() {
    local command=${1:-help}
    shift || true
    
    case $command in
        start)
            "${SCRIPT_DIR}/start.sh" "$@"
            ;;
        stop)
            "${SCRIPT_DIR}/stop.sh" "$@"
            ;;
        restart)
            "${SCRIPT_DIR}/restart.sh" "$@"
            ;;
        status)
            show_status
            ;;
        health)
            health_check
            ;;
        daemon)
            "${SCRIPT_DIR}/daemon.sh" "$@"
            ;;
        logs)
            if [ -z "$1" ]; then
                view_logs "${JAVA_SERVICE_NAME}" 100
            else
                case $1 in
                    backend)
                        view_logs "${JAVA_SERVICE_NAME}" "${2:-100}"
                        ;;
                    frontend)
                        view_logs "${FRONTEND_SERVICE_NAME}" "${2:-100}"
                        ;;
                    python)
                        view_logs "${PYTHON_SERVICE_NAME}" "${2:-100}"
                        ;;
                    golang)
                        view_logs "${GOLANG_SERVICE_NAME}" "${2:-100}"
                        ;;
                    daemon|monitor)
                        view_logs "daemon" "${2:-100}"
                        ;;
                    *)
                        view_logs "$1" "${2:-100}"
                        ;;
                esac
            fi
            ;;
        logs-all)
            view_all_logs
            ;;
        init)
            init_project
            ;;
        build)
            build_project
            ;;
        clean)
            clean_project
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
