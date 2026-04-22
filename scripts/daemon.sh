#!/bin/bash

# 实验室管理系统 - 自拉起守护脚本
# 自动监控服务状态，异常退出时自动重启

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
NC='\033[0m'

# 守护进程PID文件
DAEMON_PID_FILE="${PID_DIR}/daemon.pid"
DAEMON_LOG="${LOG_DIR}/daemon.log"

# 重启计数器目录
RESTART_COUNT_DIR="${LOG_DIR}/restart_counts"
mkdir -p "${RESTART_COUNT_DIR}"

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$DAEMON_LOG"
    
    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} ${message}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} ${message}"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} ${message}"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} ${message}"
            ;;
    esac
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

# 检查HTTP健康
check_http_health() {
    local url=$1
    local timeout=${2:-5}
    if curl -sf --connect-timeout $timeout "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查进程是否运行
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

# 获取重启计数
get_restart_count() {
    local service_name=$1
    local count_file="${RESTART_COUNT_DIR}/${service_name}.count"
    
    if [ -f "$count_file" ]; then
        # 检查是否在时间窗口内
        local count_time=$(stat -c %Y "$count_file" 2>/dev/null || stat -f %m "$count_file" 2>/dev/null)
        local current_time=$(date +%s)
        local time_diff=$((current_time - count_time))
        
        # 如果超过1小时，重置计数
        if [ $time_diff -gt 3600 ]; then
            echo 0
            return
        fi
        
        cat "$count_file"
    else
        echo 0
    fi
}

# 增加重启计数
increment_restart_count() {
    local service_name=$1
    local count_file="${RESTART_COUNT_DIR}/${service_name}.count"
    local count=$(get_restart_count $service_name)
    
    echo $((count + 1)) > "$count_file"
}

# 重置重启计数
reset_restart_count() {
    local service_name=$1
    local count_file="${RESTART_COUNT_DIR}/${service_name}.count"
    rm -f "$count_file"
}

# 发送告警
send_alert() {
    local title=$1
    local message=$2
    
    log "ERROR" "告警: $title - $message"
    
    # 邮件告警
    if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
        echo "$message" | mail -s "$title" "$ALERT_EMAIL"
    fi
    
    # Webhook告警
    if [ -n "$ALERT_WEBHOOK" ]; then
        curl -sf -X POST "$ALERT_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"title\":\"$title\",\"message\":\"$message\"}" > /dev/null 2>&1 || true
    fi
}

# 重启服务
restart_service() {
    local service_name=$1
    local service_type=$2
    local port=$3
    local health_url=$4
    
    log "INFO" "尝试重启服务: $service_name"
    
    # 检查重启次数
    local restart_count=$(get_restart_count $service_name)
    
    if [ $restart_count -ge $DAEMON_MAX_RESTART_COUNT ]; then
        log "ERROR" "服务 $service_name 重启次数超过限制 ($restart_count/$DAEMON_MAX_RESTART_COUNT)"
        send_alert "服务重启失败" "服务 $service_name 在1小时内重启次数超过限制，请人工介入"
        return 1
    fi
    
    # 停止服务
    "${SCRIPT_DIR}/stop.sh" "$service_type" > /dev/null 2>&1 || true
    
    # 等待
    sleep $DAEMON_RESTART_DELAY
    
    # 启动服务
    "${SCRIPT_DIR}/start.sh" "$service_type" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # 健康检查
        sleep 5
        if [ -n "$health_url" ]; then
            if check_http_health "$health_url" 10; then
                log "INFO" "服务 $service_name 重启成功"
                increment_restart_count $service_name
                return 0
            else
                log "ERROR" "服务 $service_name 重启后健康检查失败"
                return 1
            fi
        else
            # 端口检查
            if check_port $port; then
                log "INFO" "服务 $service_name 重启成功"
                increment_restart_count $service_name
                return 0
            else
                log "ERROR" "服务 $service_name 重启后端口未监听"
                return 1
            fi
        fi
    else
        log "ERROR" "服务 $service_name 重启失败"
        return 1
    fi
}

# 监控Java后端服务
monitor_java_backend() {
    local pid_file="${PID_DIR}/${JAVA_SERVICE_NAME}.pid"
    local health_url="http://localhost:${JAVA_PORT}/api/actuator/health"
    
    # 检查进程
    if ! check_process "$pid_file"; then
        log "WARN" "Java后端进程不存在"
        
        # 检查端口
        if check_port $JAVA_PORT; then
            log "WARN" "端口 $JAVA_PORT 被其他进程占用"
            return 1
        fi
        
        # 尝试重启
        restart_service "${JAVA_SERVICE_NAME}" "backend" "${JAVA_PORT}" "$health_url"
        return $?
    fi
    
    # 健康检查
    if ! check_http_health "$health_url"; then
        log "WARN" "Java后端健康检查失败"
        restart_service "${JAVA_SERVICE_NAME}" "backend" "${JAVA_PORT}" "$health_url"
        return $?
    fi
    
    # 重置重启计数
    reset_restart_count "${JAVA_SERVICE_NAME}"
    
    return 0
}

# 监控Python服务
monitor_python_service() {
    local pid_file="${PID_DIR}/${PYTHON_SERVICE_NAME}.pid"
    local health_url="http://localhost:${PYTHON_PORT}/health"
    
    # 检查进程
    if ! check_process "$pid_file"; then
        log "WARN" "Python服务进程不存在"
        
        if check_port $PYTHON_PORT; then
            log "WARN" "端口 $PYTHON_PORT 被其他进程占用"
            return 1
        fi
        
        restart_service "${PYTHON_SERVICE_NAME}" "python" "${PYTHON_PORT}" "$health_url"
        return $?
    fi
    
    # 端口检查
    if ! check_port $PYTHON_PORT; then
        log "WARN" "Python服务端口未监听"
        restart_service "${PYTHON_SERVICE_NAME}" "python" "${PYTHON_PORT}" "$health_url"
        return $?
    fi
    
    reset_restart_count "${PYTHON_SERVICE_NAME}"
    
    return 0
}

# 监控Golang服务
monitor_golang_service() {
    local pid_file="${PID_DIR}/${GOLANG_SERVICE_NAME}.pid"
    local health_url="http://localhost:${GOLANG_PORT}/health"
    
    # 检查进程
    if ! check_process "$pid_file"; then
        log "WARN" "Golang服务进程不存在"
        
        if check_port $GOLANG_PORT; then
            log "WARN" "端口 $GOLANG_PORT 被其他进程占用"
            return 1
        fi
        
        restart_service "${GOLANG_SERVICE_NAME}" "golang" "${GOLANG_PORT}" "$health_url"
        return $?
    fi
    
    # 端口检查
    if ! check_port $GOLANG_PORT; then
        log "WARN" "Golang服务端口未监听"
        restart_service "${GOLANG_SERVICE_NAME}" "golang" "${GOLANG_PORT}" "$health_url"
        return $?
    fi
    
    reset_restart_count "${GOLANG_SERVICE_NAME}"
    
    return 0
}

# 监控前端服务
monitor_frontend() {
    local pid_file="${PID_DIR}/${FRONTEND_SERVICE_NAME}.pid"
    
    # 检查进程
    if ! check_process "$pid_file"; then
        log "WARN" "前端服务进程不存在"
        
        if check_port $FRONTEND_PORT; then
            log "WARN" "端口 $FRONTEND_PORT 被其他进程占用"
            return 1
        fi
        
        restart_service "${FRONTEND_SERVICE_NAME}" "frontend" "${FRONTEND_PORT}" ""
        return $?
    fi
    
    # 端口检查
    if ! check_port $FRONTEND_PORT; then
        log "WARN" "前端服务端口未监听"
        restart_service "${FRONTEND_SERVICE_NAME}" "frontend" "${FRONTEND_PORT}" ""
        return $?
    fi
    
    reset_restart_count "${FRONTEND_SERVICE_NAME}"
    
    return 0
}

# 监控资源使用
monitor_resources() {
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "0")
    
    if (( $(echo "$cpu_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
        log "WARN" "CPU使用率过高: ${cpu_usage}%"
        send_alert "CPU使用率告警" "CPU使用率: ${cpu_usage}%"
    fi
    
    # 内存使用率
    local mem_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}' 2>/dev/null || echo "0")
    
    if (( $(echo "$mem_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
        log "WARN" "内存使用率过高: ${mem_usage}%"
        send_alert "内存使用率告警" "内存使用率: ${mem_usage}%"
    fi
    
    # 磁盘使用率
    local disk_usage=$(df -h / | awk '{print $5}' | sed 's/%//g' | tail -n 1 2>/dev/null || echo "0")
    
    if [ "$disk_usage" -gt 90 ]; then
        log "WARN" "磁盘使用率过高: ${disk_usage}%"
        send_alert "磁盘使用率告警" "磁盘使用率: ${disk_usage}%"
    fi
}

# 主监控循环
run_daemon() {
    log "INFO" "=========================================="
    log "INFO" "启动守护进程监控"
    log "INFO" "=========================================="
    log "INFO" "监控间隔: ${DAEMON_CHECK_INTERVAL}秒"
    log "INFO" "最大重启次数: ${DAEMON_MAX_RESTART_COUNT}次/小时"
    
    # 写入守护进程PID
    echo $$ > "$DAEMON_PID_FILE"
    
    while true; do
        log "DEBUG" "执行监控检查..."
        
        # 监控Java后端
        if [ "$JAVA_ENABLED" = true ]; then
            monitor_java_backend
        fi
        
        # 监控Python服务
        if [ "$PYTHON_ENABLED" = true ]; then
            monitor_python_service
        fi
        
        # 监控Golang服务
        if [ "$GOLANG_ENABLED" = true ]; then
            monitor_golang_service
        fi
        
        # 监控前端服务
        if [ "$FRONTEND_ENABLED" = true ]; then
            monitor_frontend
        fi
        
        # 监控资源
        monitor_resources
        
        log "DEBUG" "监控检查完成，等待 ${DAEMON_CHECK_INTERVAL} 秒..."
        sleep $DAEMON_CHECK_INTERVAL
    done
}

# 启动守护进程
start_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log "WARN" "守护进程已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    log "INFO" "启动守护进程..."
    
    # 后台运行
    nohup "$0" run >> "$DAEMON_LOG" 2>&1 &
    
    local pid=$!
    echo $pid > "$DAEMON_PID_FILE"
    
    log "INFO" "守护进程已启动 (PID: $pid)"
}

# 停止守护进程
stop_daemon() {
    if [ ! -f "$DAEMON_PID_FILE" ]; then
        log "WARN" "守护进程未运行"
        return 0
    fi
    
    local pid=$(cat "$DAEMON_PID_FILE")
    
    if ps -p $pid > /dev/null 2>&1; then
        log "INFO" "停止守护进程 (PID: $pid)..."
        kill $pid
        sleep 2
        
        if ps -p $pid > /dev/null 2>&1; then
            kill -9 $pid
        fi
    fi
    
    rm -f "$DAEMON_PID_FILE"
    log "INFO" "守护进程已停止"
}

# 查看守护进程状态
status_daemon() {
    if [ ! -f "$DAEMON_PID_FILE" ]; then
        echo -e "${RED}守护进程未运行${NC}"
        return 1
    fi
    
    local pid=$(cat "$DAEMON_PID_FILE")
    
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${GREEN}守护进程运行中 (PID: $pid)${NC}"
        ps -fp $pid
        return 0
    else
        echo -e "${RED}守护进程已停止 (PID: $pid)${NC}"
        return 1
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start    启动守护进程"
    echo "  stop     停止守护进程"
    echo "  restart  重启守护进程"
    echo "  status   查看守护进程状态"
    echo "  run      运行守护进程 (前台模式)"
    echo "  help     显示帮助信息"
    echo ""
    echo "说明:"
    echo "  守护进程会自动监控所有服务状态"
    echo "  当服务异常退出时会自动重启"
    echo "  默认监控间隔: ${DAEMON_CHECK_INTERVAL}秒"
    echo "  最大重启次数: ${DAEMON_MAX_RESTART_COUNT}次/小时"
}

# 主函数
main() {
    local action=${1:-help}
    
    case $action in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 2
            start_daemon
            ;;
        status)
            status_daemon
            ;;
        run)
            run_daemon
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log "ERROR" "未知命令: $action"
            show_help
            exit 1
            ;;
    esac
}

# 捕获退出信号
trap 'log "INFO" "守护进程停止"; rm -f "$DAEMON_PID_FILE"; exit 0' SIGINT SIGTERM

# 执行主函数
main "$@"
