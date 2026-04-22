#!/bin/bash

# 实验室管理系统 - 一键启动脚本
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
NC='\033[0m'

# 创建必要目录
mkdir -p "${LOG_DIR}"
mkdir -p "${PID_DIR}"

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

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# 等待端口可用
wait_for_port_available() {
    local port=$1
    local max_wait=${2:-30}
    local wait_time=0
    
    while check_port $port; do
        if [ $wait_time -ge $max_wait ]; then
            return 1
        fi
        sleep 1
        wait_time=$((wait_time + 1))
    done
    return 0
}

# 等待端口监听
wait_for_port_listen() {
    local port=$1
    local max_wait=${2:-60}
    local wait_time=0
    
    log_info "等待端口 $port 启动..."
    
    while ! check_port $port; do
        if [ $wait_time -ge $max_wait ]; then
            return 1
        fi
        sleep 2
        wait_time=$((wait_time + 2))
    done
    return 0
}

# 检查健康状态
check_health() {
    local url=$1
    local max_retries=${2:-15}
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -sf --connect-timeout 5 "$url" > /dev/null 2>&1; then
            return 0
        fi
        retry=$((retry + 1))
        sleep 2
    done
    return 1
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    if ! command -v $cmd &> /dev/null; then
        log_error "命令不存在: $cmd"
        return 1
    fi
    return 0
}

# 启动Java后端服务
start_java_backend() {
    log_step "启动Java后端服务..."
    
    local pid_file="${PID_DIR}/${JAVA_SERVICE_NAME}.pid"
    local log_file="${LOG_DIR}/${JAVA_SERVICE_NAME}.log"
    
    # 检查是否已运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_warn "Java后端服务已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口
    if check_port $JAVA_PORT; then
        log_error "端口 $JAVA_PORT 已被占用"
        return 1
    fi
    
    # 检查Java环境
    if ! check_command java; then
        log_error "请先安装Java环境"
        return 1
    fi
    
    # 检查Maven
    if ! check_command mvn; then
        log_error "请先安装Maven"
        return 1
    fi
    
    cd "${JAVA_SOURCE_PATH}"
    
    # 检查是否需要编译
    if [ ! -f "${JAVA_JAR_PATH}" ] || [ "${JAVA_JAR_PATH}" -ot "pom.xml" ] || [ "${JAVA_JAR_PATH}" -ot "src" ]; then
        log_info "编译Java项目..."
        mvn clean package ${JAVA_MAVEN_OPTS} -q
        if [ $? -ne 0 ]; then
            log_error "Java项目编译失败"
            return 1
        fi
    fi
    
    # 启动服务
    log_info "启动Java服务 (端口: $JAVA_PORT)..."
    nohup java ${JAVA_JVM_OPTS} -jar "${JAVA_JAR_PATH}" \
        --server.port=${JAVA_PORT} \
        --spring.profiles.active=${JAVA_SPRING_PROFILE} \
        > "${log_file}" 2>&1 &
    
    local pid=$!
    echo $pid > "$pid_file"
    
    # 等待启动
    if wait_for_port_listen $JAVA_PORT 60; then
        log_success "Java后端服务启动成功 (PID: $pid, Port: $JAVA_PORT)"
        
        # 健康检查
        sleep 5
        if check_health "http://localhost:${JAVA_PORT}/api/actuator/health" 10; then
            log_success "Java后端服务健康检查通过"
            return 0
        else
            log_warn "Java后端服务健康检查失败，请检查日志: ${log_file}"
            return 0
        fi
    else
        log_error "Java后端服务启动超时"
        return 1
    fi
}

# 启动Java后端服务 (开发模式)
start_java_backend_dev() {
    log_step "启动Java后端服务 (开发模式)..."
    
    local pid_file="${PID_DIR}/${JAVA_SERVICE_NAME}.pid"
    local log_file="${LOG_DIR}/${JAVA_SERVICE_NAME}.log"
    
    # 检查是否已运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_warn "Java后端服务已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口
    if check_port $JAVA_PORT; then
        log_error "端口 $JAVA_PORT 已被占用"
        return 1
    fi
    
    # 检查命令
    if ! check_command mvn; then
        log_error "请先安装Maven"
        return 1
    fi
    
    cd "${JAVA_SOURCE_PATH}"
    
    # 使用Maven启动
    log_info "使用 mvn spring-boot:run 启动..."
    nohup mvn spring-boot:run \
        -Dspring-boot.run.arguments="--server.port=${JAVA_PORT} --spring.profiles.active=${JAVA_SPRING_PROFILE}" \
        > "${log_file}" 2>&1 &
    
    local pid=$!
    echo $pid > "$pid_file"
    
    # 等待启动
    if wait_for_port_listen $JAVA_PORT 90; then
        log_success "Java后端服务启动成功 (PID: $pid, Port: $JAVA_PORT)"
        return 0
    else
        log_error "Java后端服务启动超时"
        return 1
    fi
}

# 启动Python服务
start_python_service() {
    log_step "启动Python服务..."
    
    local pid_file="${PID_DIR}/${PYTHON_SERVICE_NAME}.pid"
    local log_file="${LOG_DIR}/${PYTHON_SERVICE_NAME}.log"
    
    # 检查是否已运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_warn "Python服务已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口
    if check_port $PYTHON_PORT; then
        log_error "端口 $PYTHON_PORT 已被占用"
        return 1
    fi
    
    # 检查Python
    if ! check_command python3 && ! check_command python; then
        log_error "请先安装Python"
        return 1
    fi
    
    local python_cmd="python3"
    if ! command -v python3 &> /dev/null; then
        python_cmd="python"
    fi
    
    # 激活虚拟环境
    if [ -n "$PYTHON_VENV_PATH" ] && [ -f "$PYTHON_VENV_PATH/bin/activate" ]; then
        log_info "激活Python虚拟环境..."
        source "$PYTHON_VENV_PATH/bin/activate"
    fi
    
    # 安装依赖
    if [ -f "$PYTHON_REQUIREMENTS" ]; then
        log_info "安装Python依赖..."
        $python_cmd -m pip install -r "$PYTHON_REQUIREMENTS" -q
    fi
    
    # 启动服务
    log_info "启动Python服务 (端口: $PYTHON_PORT)..."
    nohup $python_cmd "${PYTHON_SCRIPT_PATH}" --port $PYTHON_PORT > "${log_file}" 2>&1 &
    
    local pid=$!
    echo $pid > "$pid_file"
    
    # 等待启动
    if wait_for_port_listen $PYTHON_PORT 30; then
        log_success "Python服务启动成功 (PID: $pid, Port: $PYTHON_PORT)"
        return 0
    else
        log_error "Python服务启动超时"
        return 1
    fi
}

# 启动Golang服务
start_golang_service() {
    log_step "启动Golang服务..."
    
    local pid_file="${PID_DIR}/${GOLANG_SERVICE_NAME}.pid"
    local log_file="${LOG_DIR}/${GOLANG_SERVICE_NAME}.log"
    
    # 检查是否已运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_warn "Golang服务已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口
    if check_port $GOLANG_PORT; then
        log_error "端口 $GOLANG_PORT 已被占用"
        return 1
    fi
    
    # 检查Go
    if ! check_command go; then
        log_error "请先安装Go环境"
        return 1
    fi
    
    # 编译（如果需要）
    if [ ! -f "${GOLANG_BINARY_PATH}" ]; then
        log_info "编译Golang项目..."
        cd "${GOLANG_SOURCE_PATH}"
        go build -o "${GOLANG_BINARY_PATH}" .
        if [ $? -ne 0 ]; then
            log_error "Golang项目编译失败"
            return 1
        fi
    fi
    
    # 启动服务
    log_info "启动Golang服务 (端口: $GOLANG_PORT)..."
    nohup "${GOLANG_BINARY_PATH}" --port $GOLANG_PORT > "${log_file}" 2>&1 &
    
    local pid=$!
    echo $pid > "$pid_file"
    
    # 等待启动
    if wait_for_port_listen $GOLANG_PORT 30; then
        log_success "Golang服务启动成功 (PID: $pid, Port: $GOLANG_PORT)"
        return 0
    else
        log_error "Golang服务启动超时"
        return 1
    fi
}

# 启动前端服务
start_frontend() {
    log_step "启动前端服务..."
    
    local pid_file="${PID_DIR}/${FRONTEND_SERVICE_NAME}.pid"
    local log_file="${LOG_DIR}/${FRONTEND_SERVICE_NAME}.log"
    
    # 检查是否已运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_warn "前端服务已在运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口
    if check_port $FRONTEND_PORT; then
        log_error "端口 $FRONTEND_PORT 已被占用"
        return 1
    fi
    
    # 检查Node.js
    if ! check_command node; then
        log_error "请先安装Node.js"
        return 1
    fi
    
    # 检查npm
    if ! check_command npm; then
        log_error "请先安装npm"
        return 1
    fi
    
    cd "${FRONTEND_SOURCE_PATH}"
    
    # 安装依赖
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install --silent
    fi
    
    # 启动开发服务器
    log_info "启动前端开发服务器 (端口: $FRONTEND_PORT)..."
    nohup npm run dev -- --port $FRONTEND_PORT > "${log_file}" 2>&1 &
    
    local pid=$!
    echo $pid > "$pid_file"
    
    # 等待启动
    if wait_for_port_listen $FRONTEND_PORT 60; then
        log_success "前端服务启动成功 (PID: $pid, Port: $FRONTEND_PORT)"
        log_info "访问地址: http://localhost:${FRONTEND_PORT}"
        return 0
    else
        log_error "前端服务启动超时"
        return 1
    fi
}

# 启动所有服务
start_all() {
    log_info "=========================================="
    log_info "启动所有服务"
    log_info "=========================================="
    
    local failed=()
    
    # 启动Java后端
    if [ "$JAVA_ENABLED" = true ]; then
        if ! start_java_backend; then
            failed+=("Java后端")
        fi
    fi
    
    # 启动Python服务
    if [ "$PYTHON_ENABLED" = true ]; then
        if ! start_python_service; then
            failed+=("Python服务")
        fi
    fi
    
    # 启动Golang服务
    if [ "$GOLANG_ENABLED" = true ]; then
        if ! start_golang_service; then
            failed+=("Golang服务")
        fi
    fi
    
    # 启动前端
    if [ "$FRONTEND_ENABLED" = true ]; then
        sleep 5
        if ! start_frontend; then
            failed+=("前端")
        fi
    fi
    
    # 输出结果
    echo ""
    log_info "=========================================="
    if [ ${#failed[@]} -eq 0 ]; then
        log_success "所有服务启动成功！"
        log_info "=========================================="
        echo ""
        log_info "服务地址:"
        [ "$JAVA_ENABLED" = true ] && log_info "  后端API: http://localhost:${JAVA_PORT}"
        [ "$FRONTEND_ENABLED" = true ] && log_info "  前端页面: http://localhost:${FRONTEND_PORT}"
        [ "$PYTHON_ENABLED" = true ] && log_info "  Python服务: http://localhost:${PYTHON_PORT}"
        [ "$GOLANG_ENABLED" = true ] && log_info "  Golang服务: http://localhost:${GOLANG_PORT}"
    else
        log_error "以下服务启动失败: ${failed[*]}"
        log_info "=========================================="
        return 1
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all         启动所有服务"
    echo "  backend     启动Java后端服务"
    echo "  backend-dev 启动Java后端服务 (开发模式 mvn spring-boot:run)"
    echo "  frontend    启动前端服务"
    echo "  python      启动Python服务"
    echo "  golang      启动Golang服务"
    echo "  help        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 all          # 启动所有服务"
    echo "  $0 backend      # 启动Java后端"
    echo "  $0 backend-dev  # 开发模式启动Java后端"
    echo "  $0 frontend     # 启动前端"
}

# 主函数
main() {
    local action=${1:-all}
    
    case $action in
        all)
            start_all
            ;;
        backend)
            start_java_backend
            ;;
        backend-dev)
            start_java_backend_dev
            ;;
        frontend)
            start_frontend
            ;;
        python)
            start_python_service
            ;;
        golang)
            start_golang_service
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
