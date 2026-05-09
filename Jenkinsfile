pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '', description: '部署目标IP（覆盖.env中的HOST_IP）')
        booleanParam(name: 'CLEAN_VOLUMES', defaultValue: false, description: '清理旧数据卷（会清空数据！）')
    }

    stages {
        stage('代码检出') {
            steps {
                echo '检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        stage('加载配置') {
            steps {
                sh '''
                    set -a
                    source .env
                    set +a
                    # 参数覆盖 .env
                    if [ -n "${DEPLOY_HOST}" ]; then
                        export HOST_IP="${DEPLOY_HOST}"
                    fi
                    echo "HOST_IP=${HOST_IP}  BACKEND_PORT=${BACKEND_PORT}  FRONTEND_PORT=${FRONTEND_PORT}"
                '''
            }
        }

        stage('Docker镜像构建') {
            steps {
                echo '构建Docker镜像...'
                sh '''
                    set -a && source .env && set +a
                    docker build -t lab-backend ./backend
                    docker build -t lab-frontend ./frontend
                '''
            }
        }

        stage('部署服务') {
            steps {
                echo '部署服务...'
                sh '''
                    set -a && source .env && set +a
                    [ -n "${DEPLOY_HOST}" ] && export HOST_IP="${DEPLOY_HOST}"

                    NETWORK="lab-network"
                    VOL_MYSQL="lab-mysql-data-${BUILD_NUMBER}"
                    VOL_REDIS="lab-redis-data-${BUILD_NUMBER}"

                    # 停止旧容器
                    docker rm -f lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
                    sleep 3

                    # 清理旧数据卷
                    if [ "${CLEAN_VOLUMES}" = "true" ]; then
                        for vol in $(docker volume ls -q | grep lab-mysql-data); do
                            docker volume rm "$vol" 2>/dev/null || true
                        done
                        for vol in $(docker volume ls -q | grep lab-redis-data); do
                            docker volume rm "$vol" 2>/dev/null || true
                        done
                    fi

                    docker network create ${NETWORK} 2>/dev/null || true
                    docker volume create ${VOL_MYSQL}
                    docker volume create ${VOL_REDIS}

                    echo "启动MySQL..."
                    docker run -d --name lab-mysql --restart always \
                        --network ${NETWORK} --network-alias mysql \
                        -p 3306:3306 \
                        -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
                        -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
                        -e MYSQL_USER="${MYSQL_USER}" \
                        -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
                        -e TZ=Asia/Shanghai \
                        -v ${VOL_MYSQL}:/var/lib/mysql \
                        mysql:8.0 \
                        --character-set-server=utf8mb4 \
                        --collation-server=utf8mb4_unicode_ci \
                        --default-authentication-plugin=mysql_native_password

                    echo "等待MySQL就绪..."
                    for i in $(seq 1 60); do
                        docker exec lab-mysql mysqladmin ping -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null \
                            && { echo "MySQL已就绪"; break; }
                        echo "等待MySQL... ($i/60)"
                        sleep 2
                    done

                    echo "初始化数据库..."
                    docker exec -i lab-mysql mysql -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                        --default-character-set=utf8mb4 -f ${MYSQL_DATABASE} \
                        < backend/src/main/resources/db/schema.sql || true
                    echo "数据库初始化完成"

                    echo "启动Redis..."
                    docker run -d --name lab-redis --restart always \
                        --network ${NETWORK} --network-alias redis \
                        -p 6379:6379 -v ${VOL_REDIS}:/data \
                        redis:7-alpine redis-server --appendonly yes
                    sleep 3

                    echo "启动后端..."
                    docker run -d --name lab-backend --restart always \
                        --network ${NETWORK} --network-alias backend \
                        -p ${BACKEND_PORT}:${BACKEND_PORT} \
                        -e SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-prod}" \
                        -e SERVER_PORT="${BACKEND_PORT}" \
                        -e DB_HOST=mysql -e DB_PORT=3306 \
                        -e DB_NAME="${MYSQL_DATABASE}" \
                        -e DB_USERNAME="${MYSQL_USER}" -e DB_PASSWORD="${MYSQL_PASSWORD}" \
                        -e REDIS_HOST=redis -e REDIS_PORT=6379 \
                        -e REDIS_PASSWORD="${REDIS_PASSWORD:-}" -e REDIS_DATABASE=0 \
                        -e JWT_SECRET="${JWT_SECRET}" \
                        -e JWT_EXPIRATION="${JWT_EXPIRATION:-86400000}" \
                        -e CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS:-*}" \
                        -e JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}" \
                        lab-backend

                    echo "启动前端..."
                    docker run -d --name lab-frontend --restart always \
                        --network ${NETWORK} \
                        -p ${FRONTEND_PORT:-80}:80 \
                        lab-frontend
                '''
            }
        }

        stage('健康检查') {
            steps {
                echo '检查服务健康状态...'
                sh '''
                    set -a && source .env && set +a
                    [ -n "${DEPLOY_HOST}" ] && export HOST_IP="${DEPLOY_HOST}"

                    echo "等待后端启动..."
                    sleep 30

                    for i in $(seq 1 30); do
                        code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 \
                            "http://${HOST_IP}:${BACKEND_PORT}/api/actuator/health" 2>/dev/null || echo "000")
                        if [ "$code" = "200" ]; then
                            echo "后端健康检查通过"
                            break
                        fi
                        echo "等待后端... ($i/30) HTTP=$code"
                        sleep 5
                    done

                    for i in $(seq 1 10); do
                        curl -s --connect-timeout 2 "http://${HOST_IP}:${FRONTEND_PORT}" >/dev/null 2>&1 \
                            && { echo "前端已就绪"; break; }
                        echo "等待前端... ($i/10)"
                        sleep 3
                    done
                '''
            }
        }
    }

    post {
        success {
            echo """
            ========================================
            部署完成
              前端: http://${params.DEPLOY_HOST}:${params.FRONTEND_PORT}
              后端: http://${params.DEPLOY_HOST}:${params.BACKEND_PORT}/api
              账号: admin / admin123
            ========================================
            """
        }

        failure {
            echo "部署失败，打印日志:"
            sh '''
                docker logs lab-backend --tail 80 2>/dev/null || true
                docker logs lab-mysql  --tail 30 2>/dev/null || true
            '''
        }

        always {
            cleanWs()
        }
    }
}
