#!/bin/bash

# 实验室管理系统 - 自拉起监控脚本
# 自动检测服务状态并重启异常退出的服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_DIR="${PROJECT_ROOT}/pids"
LOG_DIR="${PROJECT_ROOT}/logs"

# 监控日志
MONITOR_LOG="${LOG_DIR}/monitor.log"

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$MONITOR_LOG"
    
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
    esac
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local pid_file="${PID_DIR}/${service_name}.pid"
    
    if [ ! -f "$pid_file" ]; then
        log "WARN" "服务 $service_name PID文件不存在"
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! ps -p $pid > /dev/null 2>&1; then
        log "WARN" "服务 $service_name 已停止 (PID: $pid)"
        return 1
    fi
    
    return 0
}

# 检查端口
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查HTTP健康
check_http_health() {
    local url=$1
    if curl -sf "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 重启服务
restart_service() {
    local service_name=$1
    log "INFO" "尝试重启服务: $service_name"
    
    # 调用主服务脚本
    "${PROJECT_ROOT}/scripts/service.sh" restart "$service_name" docker
    
    if [ $? -eq 0 ]; then
        log "INFO" "服务 $service_name 重启成功"
        # 发送通知
        send_notification "服务重启成功" "服务 $service_name 已自动重启"
    else
        log "ERROR" "服务 $service_name 重启失败"
        # 发送告警
        send_notification "服务重启失败" "服务 $service_name 自动重启失败，请人工介入"
    fi
}

# 发送通知
send_notification() {
    local title=$1
    local message=$2
    
    log "INFO" "发送通知: $title - $message"
    
    # TODO: 集成邮件/短信/企业微信通知
    # 示例：企业微信机器人
    # curl -X POST "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY" \
    #     -H "Content-Type: application/json" \
    #     -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$title: $message\"}}"
}

# 监控Docker服务
monitor_docker_services() {
    log "INFO" "开始监控Docker服务..."
    
    cd "${PROJECT_ROOT}"
    
    # 获取所有服务状态
    local services=$(docker-compose ps --services)
    
    for service in $services; do
        local status=$(docker-compose ps --filter "status=running" $service 2>/dev/null | grep -c $service || echo "0")
        
        if [ "$status" -eq 0 ]; then
            log "WARN" "Docker服务 $service 未运行"
            
            # 尝试重启
            log "INFO" "尝试重启Docker服务: $service"
            docker-compose restart $service
            
            if [ $? -eq 0 ]; then
                log "INFO" "Docker服务 $service 重启成功"
            else
                log "ERROR" "Docker服务 $service 重启失败"
            fi
        fi
    done
}

# 监控端口
monitor_ports() {
    log "INFO" "开始监控端口..."
    
    local ports=("8081" "3000" "3306" "6379")
    local services=("backend" "frontend" "mysql" "redis")
    
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local service=${services[$i]}
        
        if ! check_port $port; then
            log "WARN" "端口 $port ($service) 未监听"
            # 可以在这里添加重启逻辑
        fi
    done
}

# 监控健康检查
monitor_health() {
    log "INFO" "开始健康检查..."
    
    local endpoints=(
        "http://localhost:8081/api/actuator/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if ! check_http_health "$endpoint"; then
            log "ERROR" "健康检查失败: $endpoint"
            # 可以在这里添加重启逻辑
        fi
    done
}

# 监控资源使用
monitor_resources() {
    log "INFO" "开始监控资源使用..."
    
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log "WARN" "CPU使用率过高: ${cpu_usage}%"
    fi
    
    # 内存使用率
    local mem_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        log "WARN" "内存使用率过高: ${mem_usage}%"
    fi
    
    # 磁盘使用率
    local disk_usage=$(df -h / | awk '{print $5}' | sed 's/%//g' | tail -n 1)
    
    if [ "$disk_usage" -gt 80 ]; then
        log "WARN" "磁盘使用率过高: ${disk_usage}%"
    fi
}

# 主监控循环
main() {
    log "INFO" "=========================================="
    log "INFO" "启动服务监控..."
    log "INFO" "=========================================="
    
    while true; do
        log "INFO" "执行监控检查..."
        
        # 监控Docker服务
        monitor_docker_services
        
        # 监控端口
        monitor_ports
        
        # 监控健康检查
        monitor_health
        
        # 监控资源使用
        monitor_resources
        
        log "INFO" "监控检查完成，等待60秒..."
        sleep 60
    done
}

# 捕获退出信号
trap 'log "INFO" "监控服务停止"; exit 0' SIGINT SIGTERM

# 启动监控
main
