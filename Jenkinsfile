pipeline {
    agent any

    environment {
        PROJECT_NAME = 'lab-management-system'
        NETWORK = 'lab-network'
    }

    stages {
        stage('代码检出') {
            steps {
                echo '📥 检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        stage('加载配置') {
            steps {
                echo '⚙️ 加载项目配置...'
                sh '''
                    if [ -f .env ]; then
                        export $(grep -v "^#" .env | grep -v "^$" | xargs)
                        echo "HOST_IP=${HOST_IP}"
                        echo "BACKEND_PORT=${BACKEND_PORT}"
                    else
                        echo "ERROR: .env file not found!"
                        exit 1
                    fi
                '''
                script {
                    def props = readProperties file: '.env'
                    env.HOST_IP = props['HOST_IP'] ?: '192.168.3.55'
                    env.BACKEND_PORT = props['BACKEND_PORT'] ?: '8081'
                    env.FRONTEND_PORT = props['FRONTEND_PORT'] ?: '80'
                    env.MYSQL_ROOT_PASSWORD = props['MYSQL_ROOT_PASSWORD'] ?: 'root123456'
                    env.MYSQL_DATABASE = props['MYSQL_DATABASE'] ?: 'lab_management'
                    env.MYSQL_USER = props['MYSQL_USER'] ?: 'labuser'
                    env.MYSQL_PASSWORD = props['MYSQL_PASSWORD'] ?: 'lab123456'
                    env.JWT_SECRET = props['JWT_SECRET'] ?: 'lab-management-jwt-secret-key-2024-production'
                    env.JWT_EXPIRATION = props['JWT_EXPIRATION'] ?: '86400000'
                    env.CORS_ALLOWED_ORIGINS = props['CORS_ALLOWED_ORIGINS'] ?: '*'
                    env.JAVA_OPTS = props['JAVA_OPTS'] ?: '-Xms512m -Xmx1024m -XX:+UseG1GC'
                }
                echo "HOST_IP=${env.HOST_IP} BACKEND_PORT=${env.BACKEND_PORT}"
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
                    docker network create ${NETWORK} 2>/dev/null || true

                    docker stop lab-frontend 2>/dev/null || true
                    docker rm lab-frontend 2>/dev/null || true
                    docker stop lab-backend 2>/dev/null || true
                    docker rm lab-backend 2>/dev/null || true
                    docker stop lab-redis 2>/dev/null || true
                    docker rm lab-redis 2>/dev/null || true
                    docker stop lab-mysql 2>/dev/null || true
                    docker rm lab-mysql 2>/dev/null || true

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
                    docker exec -i lab-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${WORKSPACE}/backend/src/main/resources/db/schema.sql

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
                    echo "等待服务启动..."
                    sleep 60

                    for i in $(seq 1 30); do
                        if curl -sf http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health; then
                            echo "后端服务健康检查通过"
                            break
                        fi
                        echo "等待后端服务... ($i/30)"
                        sleep 5
                    done

                    if curl -sf http://${HOST_IP}:${FRONTEND_PORT}; then
                        echo "前端服务健康检查通过"
                    fi
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
