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
                        -p 3306:3306 \
                        -e MYSQL_ROOT_PASSWORD=root123456 \
                        -e MYSQL_DATABASE=lab_management \
                        -e MYSQL_USER=labuser \
                        -e MYSQL_PASSWORD=lab123456 \
                        -e TZ=Asia/Shanghai \
                        -v lab-mysql-data:/var/lib/mysql \
                        -v ${WORKSPACE}/backend/src/main/resources/db/schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro \
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

                    echo "启动Redis..."
                    docker run -d \
                        --name lab-redis \
                        --restart always \
                        --network ${NETWORK} \
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
                        -p 8081:8081 \
                        -e SPRING_PROFILES_ACTIVE=prod \
                        -e SERVER_PORT=8081 \
                        -e DB_HOST=mysql \
                        -e DB_PORT=3306 \
                        -e DB_NAME=lab_management \
                        -e DB_USERNAME=labuser \
                        -e DB_PASSWORD=lab123456 \
                        -e REDIS_HOST=redis \
                        -e REDIS_PORT=6379 \
                        -e REDIS_PASSWORD= \
                        -e REDIS_DATABASE=0 \
                        -e JWT_SECRET=lab-management-jwt-secret-key-2024-production \
                        -e JWT_EXPIRATION=86400000 \
                        -e CORS_ALLOWED_ORIGINS="*" \
                        -e JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC" \
                        lab-backend

                    echo "启动前端服务..."
                    docker run -d \
                        --name lab-frontend \
                        --restart always \
                        --network ${NETWORK} \
                        -p 80:80 \
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
                        if curl -sf http://localhost:8081/api/actuator/health; then
                            echo "后端服务健康检查通过"
                            break
                        fi
                        echo "等待后端服务... ($i/30)"
                        sleep 5
                    done

                    if curl -sf http://localhost:80; then
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
              前端页面: http://192.168.3.55
              后端API:  http://192.168.3.55:8081/api
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
