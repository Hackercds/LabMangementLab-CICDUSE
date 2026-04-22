#!/bin/bash

# 备份脚本
# 用于在生产环境部署前备份当前版本

set -e

# 配置
BACKUP_DIR="/opt/lab-management/backups"
CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${CURRENT_DATE}"

echo "=========================================="
echo "开始备份当前版本"
echo "=========================================="

# 创建备份目录
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}

# 备份数据库
echo "📦 备份数据库..."
docker exec lab-mysql-prod mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} lab_management > ${BACKUP_DIR}/${BACKUP_NAME}/database.sql

# 备份Docker镜像
echo "📦 备份Docker镜像..."
docker save -o ${BACKUP_DIR}/${BACKUP_NAME}/backend.tar ${DOCKER_REGISTRY}/lab-management-backend:latest
docker save -o ${BACKUP_DIR}/${BACKUP_NAME}/frontend.tar ${DOCKER_REGISTRY}/lab-management-frontend:latest

# 备份配置文件
echo "📦 备份配置文件..."
cp docker-compose.prod.yml ${BACKUP_DIR}/${BACKUP_NAME}/
cp .env ${BACKUP_DIR}/${BACKUP_NAME}/ 2>/dev/null || true

# 创建备份信息文件
echo "📝 创建备份信息..."
cat > ${BACKUP_DIR}/${BACKUP_NAME}/backup_info.txt <<EOF
备份时间: ${CURRENT_DATE}
备份内容:
- 数据库: database.sql
- 后端镜像: backend.tar
- 前端镜像: frontend.tar
- 配置文件: docker-compose.prod.yml
EOF

# 压缩备份文件
echo "📦 压缩备份文件..."
cd ${BACKUP_DIR}
tar -czf ${BACKUP_NAME}.tar.gz ${BACKUP_NAME}
rm -rf ${BACKUP_NAME}

# 清理旧备份（保留最近7个）
echo "🧹 清理旧备份..."
ls -t ${BACKUP_DIR}/backup_*.tar.gz | tail -n +8 | xargs rm -f

echo "=========================================="
echo "✅ 备份完成: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "=========================================="
