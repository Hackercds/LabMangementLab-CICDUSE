#!/bin/bash
# 实验室管理系统 - 健康检查脚本
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

eval $(awk -F'[ :"]+' '
    /^app:/{s="app"} s=="app"&&/host:/{printf "export HOST_IP=%s\n",$3}
    s=="app"&&/backend_port:/{printf "export B_PORT=%s\n",$3}
    s=="app"&&/frontend_port:/{printf "export F_PORT=%s\n",$3}
' "${PROJECT_ROOT}/config/config.yaml")

HOST="${HOST_IP:-localhost}"
B_PORT="${B_PORT:-8081}"
F_PORT="${F_PORT:-80}"

echo "=========================================="
echo "  健康检查  ${HOST}:${B_PORT}"
echo "=========================================="

check_container() {
    local running=$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || echo "false")
    if [ "$running" = "true" ]; then echo "  [OK] $1"; else echo "  [FAIL] $1"; fi
}

echo "[容器]"
check_container lab-mysql
check_container lab-redis
check_container lab-backend
check_container lab-frontend

echo "[HTTP]"
curl -sf "http://${HOST}:${B_PORT}/api/actuator/health" >/dev/null 2>&1 && echo "  [OK] 后端" || echo "  [FAIL] 后端"
curl -sf "http://${HOST}:${F_PORT}" >/dev/null 2>&1 && echo "  [OK] 前端" || echo "  [FAIL] 前端"
echo "=========================================="
