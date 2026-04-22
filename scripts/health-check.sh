#!/bin/bash

# 健康检查脚本
# 检查所有服务的健康状态

set -e

# 配置
MAX_RETRIES=10
RETRY_INTERVAL=5

echo "=========================================="
echo "开始健康检查"
echo "=========================================="

# 检查MySQL
echo "🔍 检查MySQL..."
RETRY_COUNT=0
while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if docker exec lab-mysql-prod mysqladmin ping -h localhost > /dev/null 2>&1; then
        echo "✅ MySQL健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "MySQL健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep ${RETRY_INTERVAL}
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ MySQL健康检查失败"
    exit 1
fi

# 检查Redis
echo "🔍 检查Redis..."
RETRY_COUNT=0
while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if docker exec lab-redis-prod redis-cli ping | grep -q PONG; then
        echo "✅ Redis健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Redis健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep ${RETRY_INTERVAL}
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ Redis健康检查失败"
    exit 1
fi

# 检查后端服务
echo "🔍 检查后端服务..."
RETRY_COUNT=0
while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if curl -f http://localhost:8081/api/actuator/health > /dev/null 2>&1; then
        echo "✅ 后端服务健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "后端服务健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep ${RETRY_INTERVAL}
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ 后端服务健康检查失败"
    exit 1
fi

# 检查前端服务
echo "🔍 检查前端服务..."
RETRY_COUNT=0
while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    if curl -f http://localhost/ > /dev/null 2>&1; then
        echo "✅ 前端服务健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "前端服务健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep ${RETRY_INTERVAL}
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ 前端服务健康检查失败"
    exit 1
fi

# 检查API接口
echo "🔍 检查API接口..."
RETRY_COUNT=0
while [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin123"}')
    
    if [ "${RESPONSE}" = "200" ]; then
        echo "✅ API接口健康检查通过"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "API接口健康检查失败，重试 ${RETRY_COUNT}/${MAX_RETRIES}..."
    sleep ${RETRY_INTERVAL}
done

if [ ${RETRY_COUNT} -eq ${MAX_RETRIES} ]; then
    echo "❌ API接口健康检查失败"
    exit 1
fi

echo "=========================================="
echo "✅ 所有服务健康检查通过"
echo "=========================================="

# 显示服务状态
echo ""
echo "📊 服务状态:"
docker-compose -f docker-compose.prod.yml ps

exit 0
