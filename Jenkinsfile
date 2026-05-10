pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '', description: '覆盖config.yaml中的app.host')
        booleanParam(name: 'CLEAN_VOLUMES', defaultValue: false, description: '☠ 清空所有数据卷（谨慎！）')
        booleanParam(name: 'RESET_DATABASE', defaultValue: false, description: '☠ 删除并重建数据库（谨慎！）')
    }

    stages {
        stage('代码检出') {
            steps {
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        stage('Docker镜像构建') {
            steps {
                sh 'docker build -t lab-backend ./backend && docker build -t lab-frontend ./frontend'
            }
        }

        stage('部署服务') {
            steps {
                sh '''
                    eval $(awk -F"[ :\\"]+" \'
                        /^app:/{s="app"} /^database:/{s="db"} /^spring:/{s="sp"} /^cors:/{s="co"} /^jwt:/{s="jt"}
                        s=="app"&&/host:/{printf "export HOST_IP=%s\\n",$3}
                        s=="app"&&/backend_port:/{printf "export BACKEND_PORT=%s\\n",$3}
                        s=="app"&&/frontend_port:/{printf "export FRONTEND_PORT=%s\\n",$3}
                        s=="db"&&/name:/{printf "export MYSQL_DATABASE=%s\\n",$3}
                        s=="db"&&/user:/{printf "export MYSQL_USER=%s\\n",$3}
                        s=="db"&&/root_password:/{printf "export MYSQL_ROOT_PASSWORD=%s\\n",$3}
                        s=="db"&&/app_password:/{printf "export MYSQL_PASSWORD=%s\\n",$3}
                        s=="sp"&&/profiles_active:/{printf "export SPRING_PROFILES_ACTIVE=%s\\n",$3}
                        s=="co"&&/allowed_origins:/{printf "export CORS_ALLOWED_ORIGINS=%s\\n",$3}
                        s=="jt"&&/secret:/{printf "export JWT_SECRET=%s\\n",$3}
                        s=="jt"&&/expiration:/{printf "export JWT_EXPIRATION=%s\\n",$3}
                    \' config/config.yaml)
                    export JAVA_OPTS=$(sed -n \"s/.*opts: *\\\"\\(.*\\)\\\".*/\\\\1/p\" config/config.yaml)

                    HOST="${DEPLOY_HOST:-${HOST_IP}}"
                    echo "目标: ${HOST}  后端: ${BACKEND_PORT}  前端: ${FRONTEND_PORT}"

                    docker rm -f lab-frontend lab-backend lab-redis lab-mysql 2>/dev/null || true
                    sleep 3
                    [ "${CLEAN_VOLUMES}" = "true" ] && for vol in $(docker volume ls -q | grep lab-mysql-data); do docker volume rm "$vol" 2>/dev/null || true; done
                    [ "${CLEAN_VOLUMES}" = "true" ] && for vol in $(docker volume ls -q | grep lab-redis-data); do docker volume rm "$vol" 2>/dev/null || true; done

                    docker network create lab-network 2>/dev/null || true
                    docker volume create lab-mysql-data-${BUILD_NUMBER}
                    docker volume create lab-redis-data-${BUILD_NUMBER}

                    echo "MySQL..."
                    docker run -d --name lab-mysql --restart always --network lab-network --network-alias mysql \
                        -p 3306:3306 \
                        -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
                        -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
                        -e MYSQL_USER="${MYSQL_USER}" -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
                        -e TZ=Asia/Shanghai -v lab-mysql-data-${BUILD_NUMBER}:/var/lib/mysql \
                        mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password

                    for i in $(seq 1 60); do
                        docker exec lab-mysql mysqladmin ping -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null && { echo "MySQL 就绪"; break; }
                        sleep 2
                    done

                    # 数据库初始化逻辑
                    if [ "${RESET_DATABASE}" = "true" ]; then
                        echo "⚠ 删除并重建数据库..."
                        docker exec lab-mysql mysql -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE}; CREATE DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                        echo "导入表结构..."
                        docker exec -i lab-mysql mysql -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            --default-character-set=utf8mb4 ${MYSQL_DATABASE} \
                            < backend/src/main/resources/db/schema.sql
                    else
                        # 仅确保表存在（不删数据），只重置管理员密码
                        echo "确保表结构存在（保留现有数据）..."
                        docker exec -i lab-mysql mysql -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            --default-character-set=utf8mb4 -f ${MYSQL_DATABASE} \
                            < backend/src/main/resources/db/schema.sql || true
                        echo "重置管理员密码为 admin123..."
                        docker exec lab-mysql mysql -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            -e "INSERT INTO user (username,password,real_name,role,status) VALUES ('admin','\$2a\$10\$CgNT9cdBi21.gNYtDwHiUeK3.0AGczNorbrEklIbeKC/rilrlmLqW','系统管理员','ADMIN','ENABLED') ON DUPLICATE KEY UPDATE password=VALUES(password),status='ENABLED';" ${MYSQL_DATABASE} 2>/dev/null || true
                    fi

                    echo "Redis..."
                    docker run -d --name lab-redis --restart always --network lab-network --network-alias redis \
                        -p 6379:6379 -v lab-redis-data-${BUILD_NUMBER}:/data \
                        redis:7-alpine redis-server --appendonly yes
                    sleep 3

                    echo "后端..."
                    docker run -d --name lab-backend --restart always --network lab-network --network-alias backend \
                        -p ${BACKEND_PORT}:8081 \
                        -e SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE}" -e SERVER_PORT="8081" \
                        -e DB_HOST=mysql -e DB_PORT=3306 -e DB_NAME="${MYSQL_DATABASE}" \
                        -e DB_USERNAME="${MYSQL_USER}" -e DB_PASSWORD="${MYSQL_PASSWORD}" \
                        -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD="" -e REDIS_DATABASE=0 \
                        -e JWT_SECRET="${JWT_SECRET}" -e JWT_EXPIRATION="${JWT_EXPIRATION}" \
                        -e CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS}" -e JAVA_OPTS="${JAVA_OPTS}" \
                        lab-backend

                    echo "前端..."
                    docker run -d --name lab-frontend --restart always --network lab-network \
                        -p ${FRONTEND_PORT}:80 lab-frontend
                '''
            }
        }

        stage('健康检查') {
            steps {
                sh '''
                    eval $(awk -F"[ :\\"]+" \'
                        /^app:/{s="app"} /^database:/{s="db"} /^redis:/{s="re"} s=="app"&&/host:/{printf "export H=%s\\n",$3}
                        s=="app"&&/backend_port:/{printf "export B=%s\\n",$3}
                        s=="app"&&/frontend_port:/{printf "export F=%s\\n",$3}
                    \' config/config.yaml)

                    HOST="${DEPLOY_HOST:-${H}}"
                    sleep 30
                    for i in $(seq 1 30); do
                        curl -sf --connect-timeout 3 "http://${HOST}:${B}/api/actuator/health" >/dev/null 2>&1 && { echo "后端 OK"; break; }
                        sleep 5
                    done
                    for i in $(seq 1 10); do
                        curl -sf --connect-timeout 2 "http://${HOST}:${F}" >/dev/null 2>&1 && { echo "前端 OK"; break; }
                        sleep 3
                    done
                '''
            }
        }
    }

    post {
        success {
            echo "部署完成"
        }
        failure {
            sh 'docker logs lab-backend --tail 80 2>/dev/null || true; docker logs lab-mysql --tail 30 2>/dev/null || true'
        }
        always { cleanWs() }
    }
}
