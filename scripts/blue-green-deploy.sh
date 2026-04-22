#!/bin/bash

# 蓝绿部署脚本
# 实现零停机部署

set -e

# 配置
BLUE_CONTAINER="lab-backend-blue"
GREEN_CONTAINER="lab-backend-green"
CURRENT_COLOR=""
NEW_COLOR=""

echo "=========================================="
echo "开始蓝绿部署"
echo "=========================================="

# 检测当前运行的容器
if docker ps | grep -q ${BLUE_CONTAINER}; then
    CURRENT_COLOR="blue"
    NEW_COLOR="green"
    CURRENT_CONTAINER=${BLUE_CONTAINER}
    NEW_CONTAINER=${GREEN_CONTAINER}
elif docker ps | grep -q ${GREEN_CONTAINER}; then
    CURRENT_COLOR="green"
    NEW_COLOR="blue"
    CURRENT_CONTAINER=${GREEN_CONTAINER}
    NEW_CONTAINER=${BLUE_CONTAINER}
else
    echo "首次部署，使用蓝色环境"
    CURRENT_COLOR="none"
    NEW_COLOR="blue"
    NEW_CONTAINER=${BLUE_CONTAINER}
fi

echo "当前环境: ${CURRENT_COLOR}"
echo "新环境: ${NEW_COLOR}"

# 拉取最新镜像
echo "📥 拉取最新镜像..."
docker pull ${DOCKER_REGISTRY}/lab-management-backend:latest

# 启动新环境
echo "🚀 启动${NEW_COLOR}环境..."
docker run -d \
    --name ${NEW_CONTAINER} \
    --network lab-network \
    -e SPRING_PROFILES_ACTIVE=prod \
    -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/lab_management \
    -e SPRING_DATASOURCE_USERNAME=${MYSQL_USER} \
    -e SPRING_DATASOURCE_PASSWORD=${MYSQL_PASSWORD} \
    -p 8082:8081 \
    ${DOCKER_REGISTRY}/lab-management-backend:latest

# 等待新环境启动
echo "⏳ 等待新环境启动..."
sleep 30

# 健康检查
echo "🏥 健康检查..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if curl -f http://localhost:8082/api/actuator/health > /dev/null 2>&1; then
        echo "✅ 新环境健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep 5
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ 新环境健康检查失败，回滚部署"
    docker stop ${NEW_CONTAINER}
    docker rm ${NEW_CONTAINER}
    exit 1
fi

# 更新Nginx配置
echo "🔄 更新Nginx配置..."
if [ "${NEW_COLOR}" = "blue" ]; then
    sed -i 's/server backend-green/server backend-blue/g' /etc/nginx/nginx.conf
else
    sed -i 's/server backend-blue/server backend-green/g' /etc/nginx/nginx.conf
fi

# 重载Nginx
echo "🔄 重载Nginx..."
docker exec lab-nginx-lb nginx -s reload

# 等待流量切换
echo "⏳ 等待流量切换..."
sleep 10

# 停止旧环境
if [ "${CURRENT_COLOR}" != "none" ]; then
    echo "🛑 停止${CURRENT_COLOR}环境..."
    docker stop ${CURRENT_CONTAINER}
    docker rm ${CURRENT_CONTAINER}
fi

echo "=========================================="
echo "✅ 蓝绿部署完成"
echo "当前运行环境: ${NEW_COLOR}"
echo "=========================================="
