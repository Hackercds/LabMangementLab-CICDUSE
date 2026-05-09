pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '192.168.3.188', description: '部署目标机器IP（必填）')
        string(name: 'DOCKER_HOST_URI', defaultValue: '', description: '远程Docker TCP（可选）')
        string(name: 'BACKEND_PORT', defaultValue: '10081', description: '后端端口')
        string(name: 'FRONTEND_PORT', defaultValue: '10080', description: '前端端口')
        choice(name: 'SPRING_PROFILES_ACTIVE', choices: ['prod', 'test'], description: 'Spring环境')
        booleanParam(name: 'SKIP_DB_INIT', defaultValue: false, description: '跳过数据库初始化')
        booleanParam(name: 'CLEAN_VOLUMES', defaultValue: false, description: '清理旧数据卷')
    }

    environment {
        PROJECT_NAME = 'lab-management-system'
        NETWORK = 'lab-network'
        MYSQL_DATABASE = 'lab_management'
        MYSQL_USER = 'labuser'
        MYSQL_VOLUME = "lab-mysql-data-${BUILD_NUMBER}"
        REDIS_VOLUME = "lab-redis-data-${BUILD_NUMBER}"
        // 默认值开箱即用，生产环境请改用 Jenkins 凭据
        MYSQL_ROOT_PASSWORD = 'root123456'
        MYSQL_PASSWORD = 'lab123456'
        JWT_SECRET = 'lab-management-jwt-secret-key-2026-production'
    }

    stages {
        stage('代码检出') {
            steps {
                echo '检出代码...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        stage('前置校验') {
            steps {
                sh '''
                    if [ -z "${DEPLOY_HOST}" ]; then
                        echo "ERROR: DEPLOY_HOST 未设置，请在构建参数中填写部署目标IP"
                        exit 1
                    fi
                    if [ -n "${DOCKER_HOST_URI}" ]; then
                        export DOCKER_HOST="${DOCKER_HOST_URI}"
                    fi
                    docker info > /dev/null 2>&1 || { echo "ERROR: 无法连接 Docker"; exit 1; }
                    echo "Docker 连接正常, 目标主机: ${DEPLOY_HOST}"
                '''
            }
        }

        stage('Docker镜像构建') {
            steps {
                echo '构建Docker镜像...'
                sh '''
                    if [ -n "${DOCKER_HOST_URI}" ]; then
                        export DOCKER_HOST="${DOCKER_HOST_URI}"
                    fi
                    docker build -t lab-backend ./backend
                    docker build -t lab-frontend ./frontend
                '''
            }
        }

        stage('部署服务') {
            steps {
                echo '部署服务...'
                sh '''
                    if [ -n "${DOCKER_HOST_URI}" ]; then
                        export DOCKER_HOST="${DOCKER_HOST_URI}"
                    fi

                    # 停止旧容器
                    docker rm -f lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
                    sleep 3

                    # 清理旧数据卷
                    if [ "${CLEAN_VOLUMES}" = "true" ]; then
                        echo "清理旧版本数据卷..."
                        for vol in $(docker volume ls -q | grep lab-mysql-data); do
                            docker volume rm "$vol" 2>/dev/null || true
                        done
                        for vol in $(docker volume ls -q | grep lab-redis-data); do
                            docker volume rm "$vol" 2>/dev/null || true
                        done
                    fi

                    docker network create ${NETWORK} 2>/dev/null || true
                    docker volume create ${MYSQL_VOLUME}
                    docker volume create ${REDIS_VOLUME}

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
                        -v ${MYSQL_VOLUME}:/var/lib/mysql \
                        mysql:8.0 \
                        --character-set-server=utf8mb4 \
                        --collation-server=utf8mb4_unicode_ci \
                        --default-authentication-plugin=mysql_native_password

                    echo "等待MySQL就绪..."
                    for i in $(seq 1 60); do
                        if docker exec lab-mysql mysqladmin ping -h 127.0.0.1 -uroot -p${MYSQL_ROOT_PASSWORD} 2>/dev/null; then
                            echo "MySQL已就绪"
                            break
                        fi
                        echo "等待MySQL... ($i/60)"
                        sleep 2
                    done

                    # 初始化数据库（schema.sql 已包含 system_config）
                    if [ "${SKIP_DB_INIT}" != "true" ]; then
                        echo "初始化数据库..."
                        cat ${WORKSPACE}/backend/src/main/resources/db/schema.sql | docker exec -i lab-mysql mysql -h 127.0.0.1 -uroot -p${MYSQL_ROOT_PASSWORD} --default-character-set=utf8mb4 ${MYSQL_DATABASE}
                        echo "数据库初始化完成"
                    else
                        echo "跳过数据库初始化（SKIP_DB_INIT=true）"
                    fi

                    echo "启动Redis..."
                    docker run -d \
                        --name lab-redis \
                        --restart always \
                        --network ${NETWORK} \
                        --network-alias redis \
                        -p 6379:6379 \
                        -v ${REDIS_VOLUME}:/data \
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
                        -e SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE} \
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
                        -e JWT_EXPIRATION=86400000 \
                        -e CORS_ALLOWED_ORIGINS="*" \
                        -e JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC" \
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
                echo '检查服务健康状态...'
                sh '''
                    if [ -n "${DOCKER_HOST_URI}" ]; then
                        export DOCKER_HOST="${DOCKER_HOST_URI}"
                    fi

                    HOST="${DEPLOY_HOST}"

                    echo "等待Spring Boot启动..."
                    sleep 30

                    echo "检查后端端口..."
                    port_open=false
                    for i in $(seq 1 30); do
                        if curl -s --connect-timeout 2 "http://${HOST}:${BACKEND_PORT}" > /dev/null 2>&1; then
                            echo "后端端口 ${BACKEND_PORT} 已监听"
                            port_open=true
                            break
                        fi
                        echo "等待后端... ($i/30)"
                        sleep 5
                    done

                    if [ "$port_open" != "true" ]; then
                        echo "后端未启动，打印日志:"
                        docker logs lab-backend --tail 100 2>/dev/null || true
                        exit 1
                    fi

                    echo "检查后端健康状态..."
                    for i in $(seq 1 30); do
                        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://${HOST}:${BACKEND_PORT}/api/actuator/health" 2>/dev/null || echo "000")
                        if [ "$http_code" = "200" ]; then
                            echo "后端健康检查通过 (HTTP $http_code)"
                            break
                        fi
                        echo "等待健康检查... ($i/30) HTTP: $http_code"
                        sleep 5
                    done

                    echo "检查前端..."
                    sleep 3
                    for i in $(seq 1 10); do
                        if curl -s --connect-timeout 2 "http://${HOST}:${FRONTEND_PORT}" > /dev/null 2>&1; then
                            echo "前端端口 ${FRONTEND_PORT} 已监听"
                            break
                        fi
                        echo "等待前端... ($i/10)"
                        sleep 3
                    done
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline执行成功"
            echo """
            ========================================
            部署完成
            ========================================
            前端: http://${params.DEPLOY_HOST}:${params.FRONTEND_PORT}
            后端: http://${params.DEPLOY_HOST}:${params.BACKEND_PORT}/api
            健康: http://${params.DEPLOY_HOST}:${params.BACKEND_PORT}/api/actuator/health
            账号: admin / admin123
            ========================================
            """
        }

        failure {
            echo "Pipeline执行失败"
            sh '''
                echo "=== 后端日志 ==="
                docker logs lab-backend --tail 50 2>/dev/null || true
                echo "=== 前端日志 ==="
                docker logs lab-frontend --tail 50 2>/dev/null || true
                echo "=== MySQL日志 ==="
                docker logs lab-mysql --tail 50 2>/dev/null || true
            '''
        }

        always {
            cleanWs()
        }
    }
}
