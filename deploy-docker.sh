#!/bin/bash

# 实验室管理系统 - Docker一键部署脚本
# 适用于Linux服务器

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"; }

# 显示Banner
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          实验室管理系统 - Docker一键部署                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查Docker
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker未运行"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 停止旧容器
stop_old_containers() {
    log_step "停止旧容器..."
    
    docker-compose down --remove-orphans 2>/dev/null || true
    
    log_info "旧容器已停止"
}

# 清理旧镜像
clean_old_images() {
    log_step "清理旧镜像..."
    
    docker image prune -f 2>/dev/null || true
    
    log_info "旧镜像已清理"
}

# 构建镜像
build_images() {
    log_step "构建Docker镜像..."
    
    docker-compose build --no-cache
    
    log_info "Docker镜像构建完成"
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    docker-compose up -d
    
    log_info "服务启动中..."
}

# 等待服务就绪
wait_for_services() {
    log_step "等待服务就绪..."
    
    # 等待MySQL
    log_info "等待MySQL启动..."
    sleep 30
    
    # 等待后端
    log_info "等待后端服务启动..."
    local max_wait=120
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if curl -sf http://localhost:8081/api/actuator/health > /dev/null 2>&1; then
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
    
    # 等待前端
    log_info "等待前端服务启动..."
    sleep 10
    
    log_info "所有服务已启动"
}

# 显示服务状态
show_status() {
    log_step "服务状态:"
    
    docker-compose ps
    
    echo ""
    log_info "=========================================="
    log_info "部署完成！"
    log_info "=========================================="
    echo ""
    echo "访问地址:"
    echo "  前端页面: http://localhost"
    echo "  后端API:  http://localhost:8081/api"
    echo "  健康检查: http://localhost:8081/api/actuator/health"
    echo ""
    echo "默认账号:"
    echo "  管理员: admin / admin123"
    echo "  教师:   teacher / teacher123"
    echo "  学生:   student / student123"
    echo ""
    echo "查看日志:"
    echo "  docker-compose logs -f backend"
    echo "  docker-compose logs -f frontend"
    echo ""
}

# 主函数
main() {
    check_docker
    stop_old_containers
    clean_old_images
    build_images
    start_services
    wait_for_services
    show_status
}

main "$@"
