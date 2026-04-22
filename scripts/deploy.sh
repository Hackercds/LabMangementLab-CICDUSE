#!/bin/bash

# 实验室管理系统 - 自动化部署框架
# 支持多语言项目部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${PROJECT_ROOT}/deploy"
BACKUP_DIR="${PROJECT_ROOT}/backups"
LOG_DIR="${PROJECT_ROOT}/logs"

# 创建必要目录
mkdir -p "${DEPLOY_DIR}"
mkdir -p "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"

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
    echo -e "${BLUE}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    fi
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log_info "所有依赖已安装"
}

# 拉取最新代码
pull_code() {
    log_step "拉取最新代码..."
    
    cd "${PROJECT_ROOT}"
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        log_warn "有未提交的更改，请先提交或暂存"
        read -p "是否继续部署？(y/n): " choice
        if [ "$choice" != "y" ]; then
            log_info "部署已取消"
            exit 0
        fi
    fi
    
    # 拉取代码
    git pull origin main
    
    log_info "代码拉取完成"
}

# 备份当前版本
backup_current() {
    log_step "备份当前版本..."
    
    local backup_name="backup_$(date '+%Y%m%d_%H%M%S')"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    mkdir -p "${backup_path}"
    
    # 备份配置文件
    if [ -f "${PROJECT_ROOT}/.env" ]; then
        cp "${PROJECT_ROOT}/.env" "${backup_path}/"
    fi
    
    # 备份Docker镜像
    docker save -o "${backup_path}/images.tar" \
        $(docker images --format '{{.Repository}}:{{.Tag}}' | grep 'lab-management') || true
    
    # 备份数据库
    docker exec lab-mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" \
        lab_management > "${backup_path}/database.sql" || true
    
    log_info "备份完成: ${backup_path}"
}

# 构建镜像
build_images() {
    log_step "构建Docker镜像..."
    
    cd "${PROJECT_ROOT}"
    
    # 构建后端镜像
    log_info "构建后端镜像..."
    docker build -t lab-management-backend:latest ./backend
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    docker build -t lab-management-frontend:latest ./frontend
    
    log_info "镜像构建完成"
}

# 停止旧服务
stop_services() {
    log_step "停止旧服务..."
    
    cd "${PROJECT_ROOT}"
    
    docker-compose down
    
    log_info "旧服务已停止"
}

# 启动新服务
start_services() {
    log_step "启动新服务..."
    
    cd "${PROJECT_ROOT}"
    
    docker-compose up -d
    
    log_info "新服务已启动"
}

# 健康检查
health_check() {
    log_step "执行健康检查..."
    
    local max_retries=30
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -sf http://localhost:8081/api/actuator/health > /dev/null 2>&1; then
            log_info "健康检查通过"
            return 0
        fi
        
        retry=$((retry + 1))
        log_info "等待服务启动... ($retry/$max_retries)"
        sleep 2
    done
    
    log_error "健康检查失败"
    return 1
}

# 运行冒烟测试
run_smoke_tests() {
    log_step "运行冒烟测试..."
    
    cd "${PROJECT_ROOT}/tests"
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt -q
        python run_tests.py smoke
        
        if [ $? -eq 0 ]; then
            log_info "冒烟测试通过"
            return 0
        else
            log_error "冒烟测试失败"
            return 1
        fi
    else
        log_warn "未找到测试文件，跳过冒烟测试"
        return 0
    fi
}

# 回滚
rollback() {
    log_step "执行回滚..."
    
    local latest_backup=$(ls -t "${BACKUP_DIR}" | head -n 1)
    
    if [ -z "$latest_backup" ]; then
        log_error "未找到备份文件"
        return 1
    fi
    
    local backup_path="${BACKUP_DIR}/${latest_backup}"
    
    log_info "使用备份: ${backup_path}"
    
    # 恢复配置文件
    if [ -f "${backup_path}/.env" ]; then
        cp "${backup_path}/.env" "${PROJECT_ROOT}/"
    fi
    
    # 恢复Docker镜像
    if [ -f "${backup_path}/images.tar" ]; then
        docker load -i "${backup_path}/images.tar"
    fi
    
    # 恢复数据库
    if [ -f "${backup_path}/database.sql" ]; then
        docker exec -i lab-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
            lab_management < "${backup_path}/database.sql"
    fi
    
    # 重启服务
    cd "${PROJECT_ROOT}"
    docker-compose down
    docker-compose up -d
    
    log_info "回滚完成"
}

# 清理旧备份
cleanup_old_backups() {
    log_step "清理旧备份..."
    
    local retention_days=7
    local cutoff_date=$(date -d "-${retention_days} days" +%Y%m%d)
    
    find "${BACKUP_DIR}" -type d -name "backup_*" | while read backup; do
        local backup_date=$(basename "$backup" | grep -o '[0-9]\{8\}')
        
        if [ "$backup_date" \< "$cutoff_date" ]; then
            log_info "删除旧备份: $backup"
            rm -rf "$backup"
        fi
    done
    
    log_info "旧备份清理完成"
}

# 发送通知
send_notification() {
    local status=$1
    local message=$2
    
    log_info "发送通知: $status - $message"
    
    # TODO: 集成邮件/短信/企业微信通知
}

# 主部署流程
main() {
    log_info "=========================================="
    log_info "开始自动化部署"
    log_info "=========================================="
    
    local start_time=$(date +%s)
    
    # 1. 检查依赖
    check_dependencies
    
    # 2. 拉取代码
    pull_code
    
    # 3. 备份当前版本
    backup_current
    
    # 4. 构建镜像
    build_images
    
    # 5. 停止旧服务
    stop_services
    
    # 6. 启动新服务
    start_services
    
    # 7. 健康检查
    if ! health_check; then
        log_error "健康检查失败，执行回滚"
        rollback
        send_notification "部署失败" "健康检查失败，已自动回滚"
        exit 1
    fi
    
    # 8. 冒烟测试
    if ! run_smoke_tests; then
        log_error "冒烟测试失败，执行回滚"
        rollback
        send_notification "部署失败" "冒烟测试失败，已自动回滚"
        exit 1
    fi
    
    # 9. 清理旧备份
    cleanup_old_backups
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "=========================================="
    log_info "部署完成！耗时: ${duration}秒"
    log_info "=========================================="
    
    send_notification "部署成功" "部署完成，耗时: ${duration}秒"
}

# 执行主函数
main "$@"
