#!/bin/bash
# 实验室管理系统 - 备份脚本
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

source "${PROJECT_ROOT}/.env" 2>/dev/null || true

echo "=========================================="
echo "  开始备份"
echo "=========================================="

mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# 备份数据库 (使用MySQL容器内的root账号)
echo "[1/4] 备份数据库..."
docker exec lab-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE:-lab_management} \
    > "${BACKUP_DIR}/${BACKUP_NAME}/database.sql" 2>/dev/null && echo "  数据库已备份" || echo "  数据库备份跳过"

# 备份Docker镜像
echo "[2/4] 备份镜像..."
docker save lab-backend:latest -o "${BACKUP_DIR}/${BACKUP_NAME}/backend.tar" 2>/dev/null || true
docker save lab-frontend:latest -o "${BACKUP_DIR}/${BACKUP_NAME}/frontend.tar" 2>/dev/null || true

# 备份配置文件
echo "[3/4] 备份配置..."
cp "${PROJECT_ROOT}/.env" "${BACKUP_DIR}/${BACKUP_NAME}/" 2>/dev/null || true

# 打包
echo "[4/4] 打包..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}" && rm -rf "${BACKUP_NAME}"

# 只保留最近7个
ls -t backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo "=========================================="
echo "  备份完成: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "=========================================="
