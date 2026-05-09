#!/bin/bash
# 实验室管理系统 - 备份脚本
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# 从 config.yaml 加载
eval $(awk -F'[ :"]+' '
    /^database:/{s="db"} /^app:/{s="app"}
    s=="db"&&/name:/  {printf "export DB=%s\n",$3}
    s=="db"&&/root_password:/{printf "export PW=%s\n",$3}
' "${PROJECT_ROOT}/config/config.yaml")

echo "=========================================="
echo "  开始备份"
echo "=========================================="

mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

echo "[1/3] 备份数据库..."
docker exec lab-mysql mysqldump -u root -p"${PW}" ${DB:-lab_management} \
    > "${BACKUP_DIR}/${BACKUP_NAME}/database.sql" 2>/dev/null && echo "  数据库已备份" || echo "  跳过"

echo "[2/3] 备份镜像..."
docker save lab-backend:latest -o "${BACKUP_DIR}/${BACKUP_NAME}/backend.tar" 2>/dev/null || true
docker save lab-frontend:latest -o "${BACKUP_DIR}/${BACKUP_NAME}/frontend.tar" 2>/dev/null || true

echo "[3/3] 打包..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}" && rm -rf "${BACKUP_NAME}"
ls -t backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo "=========================================="
echo "  备份完成: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "=========================================="
