#!/bin/bash
# 实验室管理系统 - 健康检查脚本
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/.env" 2>/dev/null || true

HOST="${HOST_IP:-localhost}"
B_PORT="${BACKEND_PORT:-8081}"
F_PORT="${FRONTEND_PORT:-80}"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo "=========================================="
echo "  健康检查"
echo "=========================================="

check_container() {
    local name=$1
    local running=$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || echo "false")
    if [ "$running" = "true" ]; then
        echo "  [OK] $name"
        return 0
    else
        echo "  [FAIL] $name 未运行"
        return 1
    fi
}

check_url() {
    local url=$1
    local desc=$2
    for i in $(seq 1 $MAX_RETRIES); do
        if curl -sf "$url" >/dev/null 2>&1; then
            echo "  [OK] $desc ($url)"
            return 0
        fi
        sleep $RETRY_INTERVAL
    done
    echo "  [FAIL] $desc ($url)"
    return 1
}

all_ok=true

echo "[容器状态]"
check_container lab-mysql || all_ok=false
check_container lab-redis || all_ok=false
check_container lab-backend || all_ok=false
check_container lab-frontend || all_ok=false

echo "[HTTP检查]"
check_url "http://${HOST}:${B_PORT}/api/actuator/health" "后端健康" || all_ok=false
check_url "http://${HOST}:${F_PORT}" "前端页面" || all_ok=false

echo "=========================================="
if [ "$all_ok" = "true" ]; then
    echo "  全部服务正常"
else
    echo "  部分服务异常，请检查日志"
fi
echo "=========================================="
