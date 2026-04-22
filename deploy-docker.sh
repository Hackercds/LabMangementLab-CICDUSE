#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          实验室管理系统 - Docker一键部署                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

load_env() {
    log_step "加载配置..."
    if [ -f "${SCRIPT_DIR}/.env" ]; then
        set -a
        source "${SCRIPT_DIR}/.env"
        set +a
        log_info "配置加载完成 HOST_IP=${HOST_IP} BACKEND_PORT=${BACKEND_PORT}"
    else
        log_error ".env 文件不存在！"
        exit 1
    fi
}

check_docker() {
    log_step "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        log_error "Docker未运行"
        exit 1
    fi
    log_info "Docker环境检查通过"
}

stop_old_containers() {
    log_step "停止旧容器..."
    docker stop lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
    docker rm lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
    log_info "旧容器已停止"
}

build_images() {
    log_step "构建Docker镜像..."
    docker build -t lab-backend ./backend
    docker build -t lab-frontend ./frontend
    log_info "Docker镜像构建完成"
}

start_services() {
    log_step "启动服务..."

    docker network create lab-network 2>/dev/null || true
    docker volume create lab-mysql-data 2>/dev/null || true
    docker volume create lab-redis-data 2>/dev/null || true

    docker run -d \
        --name lab-mysql \
        --restart always \
        --network lab-network \
        --network-alias mysql \
        -p ${MYSQL_PORT:-3306}:3306 \
        -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
        -e MYSQL_DATABASE=${MYSQL_DATABASE} \
        -e MYSQL_USER=${MYSQL_USER} \
        -e MYSQL_PASSWORD=${MYSQL_PASSWORD} \
        -e TZ=Asia/Shanghai \
        -v lab-mysql-data:/var/lib/mysql \
        mysql:8.0 \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci \
        --default-authentication-plugin=mysql_native_password

    log_info "等待MySQL启动..."
    for i in $(seq 1 30); do
        if docker exec lab-mysql mysqladmin ping -h localhost 2>/dev/null; then
            log_info "MySQL已就绪"
            break
        fi
        sleep 5
    done

    docker exec -i lab-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${SCRIPT_DIR}/backend/src/main/resources/db/schema.sql

    docker run -d \
        --name lab-redis \
        --restart always \
        --network lab-network \
        --network-alias redis \
        -p ${REDIS_PORT:-6379}:6379 \
        -v lab-redis-data:/data \
        redis:7-alpine \
        redis-server --appendonly yes

    sleep 3

    docker run -d \
        --name lab-backend \
        --restart always \
        --network lab-network \
        --network-alias backend \
        -p ${BACKEND_PORT}:${BACKEND_PORT} \
        -e SPRING_PROFILES_ACTIVE=prod \
        -e SERVER_PORT=${BACKEND_PORT} \
        -e DB_HOST=mysql \
        -e DB_PORT=3306 \
        -e DB_NAME=${MYSQL_DATABASE} \
        -e DB_USERNAME=${MYSQL_USER} \
        -e DB_PASSWORD=${MYSQL_PASSWORD} \
        -e REDIS_HOST=redis \
        -e REDIS_PORT=6379 \
        -e REDIS_PASSWORD= \
        -e REDIS_DATABASE=0 \
        -e JWT_SECRET=${JWT_SECRET} \
        -e JWT_EXPIRATION=${JWT_EXPIRATION} \
        -e CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}" \
        -e JAVA_OPTS="${JAVA_OPTS}" \
        lab-backend

    docker run -d \
        --name lab-frontend \
        --restart always \
        --network lab-network \
        -p ${FRONTEND_PORT}:80 \
        lab-frontend

    log_info "服务启动中..."
}

wait_for_services() {
    log_step "等待服务就绪..."
    sleep 30

    local max_wait=120
    local wait_time=0
    while [ $wait_time -lt $max_wait ]; do
        if curl -sf http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health > /dev/null 2>&1; then
            log_info "后端服务已就绪"
            break
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        log_info "等待后端服务... (${wait_time}s/${max_wait}s)"
    done

    if [ $wait_time -ge $max_wait ]; then
        log_warn "后端服务启动超时，请检查日志"
    fi
}

show_status() {
    log_step "服务状态:"
    docker ps --filter "name=lab-"

    echo ""
    log_info "=========================================="
    log_info "部署完成！"
    log_info "=========================================="
    echo ""
    echo "访问地址:"
    echo "  前端页面: http://${HOST_IP}:${FRONTEND_PORT}"
    echo "  后端API:  http://${HOST_IP}:${BACKEND_PORT}/api"
    echo "  健康检查: http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health"
    echo ""
    echo "默认账号:"
    echo "  管理员: admin / admin123"
    echo ""
    echo "查看日志:"
    echo "  docker logs -f lab-backend"
    echo "  docker logs -f lab-frontend"
    echo ""
}

main() {
    load_env
    check_docker
    stop_old_containers
    build_images
    start_services
    wait_for_services
    show_status
}

main "$@"
