pipeline {
    agent any

    environment {
        PROJECT_NAME = 'lab-management-system'
        NETWORK = 'lab-network'
        HOST_IP = '192.168.3.55'
        BACKEND_PORT = '8081'
        FRONTEND_PORT = '80'
        MYSQL_ROOT_PASSWORD = 'root123456'
        MYSQL_DATABASE = 'lab_management'
        MYSQL_USER = 'labuser'
        MYSQL_PASSWORD = 'lab123456'
        JWT_SECRET = 'lab-management-jwt-secret-key-2024-production'
        JWT_EXPIRATION = '86400000'
        CORS_ALLOWED_ORIGINS = '*'
        JAVA_OPTS = '-Xms512m -Xmx1024m -XX:+UseG1GC'
    }

    stages {
        stage('代码检出') {
            steps {
                echo '📥 检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        stage('Docker镜像构建') {
            steps {
                echo '🐳 构建Docker镜像（含后端+前端编译）...'
                sh '''
                    docker build -t lab-backend ./backend
                    docker build -t lab-frontend ./frontend
                '''
            }
        }

        stage('部署服务') {
            steps {
                echo '🚀 部署服务...'
                sh '''
                    docker rm -f lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true

                    docker network create ${NETWORK} 2>/dev/null || true

                    docker volume create lab-mysql-data 2>/dev/null || true
                    docker volume create lab-redis-data 2>/dev/null || true

                    echo "启动MySQL..."
                    docker run -d \
                        --name lab-mysql \
                        --restart always \
                        --network ${NETWORK} \
                        --network-alias mysql \
                        -p 3306:3306 \
                        -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
                        -e MYSQL_DATABASE=${MYSQL_DATABASE} \
                        -e MYSQL_USER=${MYSQL_USER} \
                        -e MYSQL_PASSWORD=${MYSQL_PASSWORD} \
                        -e TZ=Asia/Shanghai \
                        -v lab-mysql-data:/var/lib/mysql \
                        mysql:8.0 \
                        --character-set-server=utf8mb4 \
                        --collation-server=utf8mb4_unicode_ci \
                        --default-authentication-plugin=mysql_native_password

                    echo "等待MySQL就绪..."
                    for i in $(seq 1 30); do
                        if docker exec lab-mysql mysqladmin ping -h localhost 2>/dev/null; then
                            echo "MySQL已就绪"
                            break
                        fi
                        echo "等待MySQL... ($i/30)"
                        sleep 5
                    done

                    echo "初始化数据库..."
                    docker exec -i lab-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD} <<'SQL'
CREATE DATABASE IF NOT EXISTS lab_management DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL
                    sleep 3
                    docker exec -i lab-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD} lab_management < ${WORKSPACE}/backend/src/main/resources/db/schema.sql
                    echo "数据库初始化完成"

                    echo "启动Redis..."
                    docker run -d \
                        --name lab-redis \
                        --restart always \
                        --network ${NETWORK} \
                        --network-alias redis \
                        -p 6379:6379 \
                        -v lab-redis-data:/data \
                        redis:7-alpine \
                        redis-server --appendonly yes

                    sleep 3

                    echo "启动后端服务..."
                    docker run -d \
                        --name lab-backend \
                        --restart always \
                        --network ${NETWORK} \
                        --network-alias backend \
                        -p ${BACKEND_PORT}:${BACKEND_PORT} \
                        -e SPRING_PROFILES_ACTIVE=prod \
                        -e SERVER_PORT=${BACKEND_PORT} \
                        -e DB_HOST=mysql \
                        -e DB_PORT=3306 \
                        -e DB_NAME=${MYSQL_DATABASE} \
                        -e DB_USERNAME=${MYSQL_USER} \
                        -e DB_PASSWORD=${MYSQL_PASSWORD} \
                        -e REDIS_HOST=redis \
                        -e REDIS_PORT=6379 \
                        -e REDIS_PASSWORD= \
                        -e REDIS_DATABASE=0 \
                        -e JWT_SECRET=${JWT_SECRET} \
                        -e JWT_EXPIRATION=${JWT_EXPIRATION} \
                        -e CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}" \
                        -e JAVA_OPTS="${JAVA_OPTS}" \
                        lab-backend

                    echo "启动前端服务..."
                    docker run -d \
                        --name lab-frontend \
                        --restart always \
                        --network ${NETWORK} \
                        -p ${FRONTEND_PORT}:80 \
                        lab-frontend
                '''
            }
        }

        stage('健康检查') {
            steps {
                echo '🏥 检查服务健康状态...'
                sh '''
                    echo "等待Spring Boot启动（冷启动较慢）..."
                    sleep 30

                    echo "检查后端端口监听..."
                    port_open=false
                    for i in $(seq 1 30); do
                        if (echo > /dev/tcp/${HOST_IP}/${BACKEND_PORT}) 2>/dev/null; then
                            echo "后端端口 ${BACKEND_PORT} 已监听"
                            port_open=true
                            break
                        fi
                        echo "等待后端端口监听... ($i/30)"
                        sleep 5
                    done

                    if [ "$port_open" != "true" ]; then
                        echo "后端端口 ${BACKEND_PORT} 未启动，打印日志："
                        docker logs lab-backend --tail 100 2>/dev/null || true
                        exit 1
                    fi

                    echo "检查后端健康状态..."
                    for i in $(seq 1 30); do
                        http_code=$(curl -s -o /dev/null -w "%{http_code}" http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health 2>/dev/null || echo "000")
                        if [ "$http_code" = "200" ]; then
                            echo "后端健康检查通过 (HTTP $http_code)"
                            break
                        fi
                        echo "等待后端健康... ($i/30) HTTP状态: $http_code"
                        sleep 5
                    done

                    echo "检查前端端口监听..."
                    for i in $(seq 1 10); do
                        if (echo > /dev/tcp/${HOST_IP}/${FRONTEND_PORT}) 2>/dev/null; then
                            echo "前端端口 ${FRONTEND_PORT} 已监听"
                            break
                        fi
                        echo "等待前端端口监听... ($i/10)"
                        sleep 3
                    done
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline执行成功！'
            echo """
            ========================================
            部署完成！
            ========================================
            访问地址:
              前端页面: http://${env.HOST_IP}:${env.FRONTEND_PORT}
              后端API:  http://${env.HOST_IP}:${env.BACKEND_PORT}/api
            默认账号:
              管理员: admin / admin123
            ========================================
            """
        }

        failure {
            echo '❌ Pipeline执行失败！'
            sh '''
                docker logs lab-backend --tail 50 2>/dev/null || true
                docker logs lab-frontend --tail 50 2>/dev/null || true
                docker logs lab-mysql --tail 50 2>/dev/null || true
            '''
        }

        always {
            echo '🧹 清理工作空间...'
            dir(env.WORKSPACE) {
                deleteDir()
            }
        }
    }
}
