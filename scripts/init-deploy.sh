#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error(){ echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          实验室管理系统 - Docker一键部署                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 从 config/config.yaml 加载配置
load_config() {
    local cfg="${PROJECT_ROOT}/config/config.yaml"
    [ ! -f "$cfg" ] && { log_error "config/config.yaml 不存在！"; exit 1; }

    eval $(awk -F'[ :"]+' '
        /^app:/{s="app"} /^database:/{s="db"} /^spring:/{s="sp"} /^cors:/{s="co"} /^java:/{s="jv"} /^jwt:/{s="jt"}
        s=="app"&&/host:/           {printf "export HOST_IP=%s\n",$3}
        s=="app"&&/backend_port:/   {printf "export BACKEND_PORT=%s\n",$3}
        s=="app"&&/frontend_port:/  {printf "export FRONTEND_PORT=%s\n",$3}
        s=="db"&&/name:/            {printf "export MYSQL_DATABASE=%s\n",$3}
        s=="db"&&/user:/            {printf "export MYSQL_USER=%s\n",$3}
        s=="db"&&/root_password:/   {printf "export MYSQL_ROOT_PASSWORD=%s\n",$3}
        s=="db"&&/app_password:/    {printf "export MYSQL_PASSWORD=%s\n",$3}
        s=="sp"&&/profiles_active:/ {printf "export SPRING_PROFILES_ACTIVE=%s\n",$3}
        s=="co"&&/allowed_origins:/ {printf "export CORS_ALLOWED_ORIGINS=%s\n",$3}
        s=="jt"&&/secret:/          {printf "export JWT_SECRET=%s\n",$3}
        s=="jt"&&/expiration:/      {printf "export JWT_EXPIRATION=%s\n",$3}
    ' "$cfg")
    export JAVA_OPTS=$(sed -n 's/.*opts: *"\(.*\)".*/\1/p' "$cfg")

    log_info "HOST=${HOST_IP}  BACKEND=${BACKEND_PORT}  FRONTEND=${FRONTEND_PORT}"
}

check_docker() {
    log_step "检查Docker..."
    command -v docker &>/dev/null || { log_error "Docker未安装"; exit 1; }
    docker info &>/dev/null || { log_error "Docker未运行"; exit 1; }
    log_info "Docker OK"
}

stop_old() {
    log_step "停止旧容器..."
    docker stop lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
    docker rm lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
}

build_images() {
    log_step "构建镜像..."
    docker build -t lab-backend "${PROJECT_ROOT}/backend"
    docker build -t lab-frontend "${PROJECT_ROOT}/frontend"
}

start_services() {
    log_step "启动服务..."
    docker network create lab-network 2>/dev/null || true
    docker volume create lab-mysql-data 2>/dev/null || true
    docker volume create lab-redis-data 2>/dev/null || true

    docker run -d --name lab-mysql --restart always --network lab-network --network-alias mysql \
        -p 3306:3306 \
        -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
        -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
        -e MYSQL_USER="${MYSQL_USER}" -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
        -e TZ=Asia/Shanghai -v lab-mysql-data:/var/lib/mysql \
        mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password

    for i in $(seq 1 30); do
        docker exec lab-mysql mysqladmin ping -h localhost 2>/dev/null && { log_info "MySQL 就绪"; break; }
        sleep 5
    done

    docker exec -i lab-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -f ${MYSQL_DATABASE} \
        < "${PROJECT_ROOT}/backend/src/main/resources/db/schema.sql" || true

    docker run -d --name lab-redis --restart always --network lab-network --network-alias redis \
        -p 6379:6379 -v lab-redis-data:/data redis:7-alpine redis-server --appendonly yes
    sleep 3

    docker run -d --name lab-backend --restart always --network lab-network --network-alias backend \
        -p ${BACKEND_PORT}:${BACKEND_PORT} \
        -e SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE}" -e SERVER_PORT="${BACKEND_PORT}" \
        -e DB_HOST=mysql -e DB_PORT=3306 -e DB_NAME="${MYSQL_DATABASE}" \
        -e DB_USERNAME="${MYSQL_USER}" -e DB_PASSWORD="${MYSQL_PASSWORD}" \
        -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD="" -e REDIS_DATABASE=0 \
        -e JWT_SECRET="${JWT_SECRET}" -e JWT_EXPIRATION="${JWT_EXPIRATION}" \
        -e CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}" -e JAVA_OPTS="${JAVA_OPTS}" \
        lab-backend

    docker run -d --name lab-frontend --restart always --network lab-network \
        -p ${FRONTEND_PORT}:80 lab-frontend
}

wait_for_services() {
    log_step "等待服务就绪..."
    sleep 30
    for i in $(seq 1 30); do
        curl -sf --connect-timeout 3 "http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health" >/dev/null 2>&1 && { log_info "后端 OK"; break; }
        sleep 5
    done
}

show_status() {
    docker ps --filter "name=lab-"
    echo ""
    echo "  前端: http://${HOST_IP}:${FRONTEND_PORT}"
    echo "  后端: http://${HOST_IP}:${BACKEND_PORT}/api"
    echo "  账号: admin / admin123"
}

load_config
check_docker
stop_old
build_images
start_services
wait_for_services
show_status
