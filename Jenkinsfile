pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '', description: '覆盖config.yaml中的app.host')
        booleanParam(name: 'CLEAN_VOLUMES', defaultValue: false, description: '☠ 清空所有数据卷（谨慎！）')
        booleanParam(name: 'RESET_DATABASE', defaultValue: false, description: '☠ 删除并重建数据库（谨慎！）')
        booleanParam(name: 'RESET_ADMIN', defaultValue: true, description: '重置管理员密码为admin123（默认开启）')
        booleanParam(name: 'DEPLOY_MONITOR', defaultValue: false, description: '部署监控系统（Grafana+Prometheus）')
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
                    # volume 创建失败不影响（docker run -v 会自动创建），加重试以防临时网络抖动
                    for i in 1 2 3; do docker volume create lab-mysql-data 2>/dev/null && break || sleep 3; done || true
                    for i in 1 2 3; do docker volume create lab-redis-data 2>/dev/null && break || sleep 3; done || true

                    echo "MySQL..."
                    docker run -d --name lab-mysql --restart always --network lab-network --network-alias mysql \
                        -p 3306:3306 \
                        -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
                        -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
                        -e MYSQL_USER="${MYSQL_USER}" -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
                        -e TZ=Asia/Shanghai -v lab-mysql-data:/var/lib/mysql \
                        mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-authentication-plugin=mysql_native_password

                    echo "等待 MySQL 就绪..."
                    for i in $(seq 1 60); do
                        docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1 && { echo "MySQL 就绪"; break; }
                        sleep 2
                    done
                    # 确认 MySQL 真正可用
                    docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1 || { echo "❌ MySQL 未就绪，退出"; exit 1; }

                    # 数据库初始化逻辑
                    if [ "${RESET_DATABASE}" = "true" ]; then
                        echo "⚠ 删除并重建数据库..."
                        docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE}; CREATE DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
                        echo "导入表结构..."
                        docker exec -i lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            --default-character-set=utf8mb4 ${MYSQL_DATABASE} \
                            < backend/src/main/resources/db/schema.sql
                        echo "✅ 表结构导入完成"
                    else
                        echo "确保表结构存在（保留现有数据）..."
                        # 检查 user 表是否存在，不存在则完整导入，存在则用 -f 增量导入
                        if docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1 FROM user LIMIT 1" ${MYSQL_DATABASE} >/dev/null 2>&1; then
                            echo "数据库已有表，使用增量模式..."
                            docker exec -i lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                                --default-character-set=utf8mb4 -f ${MYSQL_DATABASE} \
                                < backend/src/main/resources/db/schema.sql || true
                        else
                            echo "数据库无表，完整导入..."
                            docker exec -i lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                                --default-character-set=utf8mb4 ${MYSQL_DATABASE} \
                                < backend/src/main/resources/db/schema.sql
                            echo "✅ 表结构导入完成"
                        fi
                        # 修复已有数据库的 JSON→TEXT 列类型
                        docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -f ${MYSQL_DATABASE} \
                            -e "ALTER TABLE operation_log MODIFY COLUMN before_snapshot TEXT; ALTER TABLE operation_log MODIFY COLUMN after_snapshot TEXT;" 2>/dev/null || true
                    fi

                    if [ "${RESET_ADMIN}" = "true" ]; then
                        echo "重置管理员密码为 admin123..."
                        docker exec lab-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
                            -e "DELETE FROM user WHERE username='\''admin'\''; INSERT INTO user (username,password,real_name,role,status) VALUES ('\''admin'\'', '\''PLACEHOLDER'\'', '\''系统管理员'\'', '\''ADMIN'\'', '\''ENABLED'\'');" ${MYSQL_DATABASE} 2>/dev/null || true
                        echo "已删除旧admin记录，应用启动后将自动创建新的admin/admin123"
                    fi

                    echo "Redis..."
                    docker run -d --name lab-redis --restart always --network lab-network --network-alias redis \
                        -p 6379:6379 -v lab-redis-data:/data \
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

                    if [ "${DEPLOY_MONITOR}" = "true" ]; then
                        echo "========================================"
                        echo "        部署全栈监控系统"
                        echo "========================================"
                        set +e  # 监控服务不影响主部署

                        echo ">>> 清理旧监控容器..."
                        docker rm -f lab-prometheus lab-grafana lab-alertmanager lab-loki lab-promtail lab-node-exporter lab-cadvisor lab-mysql-exporter lab-redis-exporter lab-blackbox-exporter 2>/dev/null || true
                        docker volume create lab-prometheus-data lab-grafana-data lab-alertmanager-data lab-loki-data 2>/dev/null || true

                        echo ">>> 同步监控配置到目标主机..."
                        MONITOR_SYNC_OK=true
                        cd monitor
                        tar czf - . | docker run --rm -i -v /opt/lab-monitor:/out alpine sh -c "cd /out && tar xzf - && echo '配置同步完成'" || MONITOR_SYNC_OK=false
                        cd ..

                        echo ">>> 启动 Prometheus..."
                        docker run -d --name lab-prometheus --restart always --network lab-network --network-alias prometheus \
                            -p 9090:9090 \
                            -v /opt/lab-monitor/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
                            -v /opt/lab-monitor/prometheus/alert_rules.yml:/etc/prometheus/alert_rules.yml:ro \
                            -v lab-prometheus-data:/prometheus \
                            prom/prometheus:v2.45.0 \
                            --config.file=/etc/prometheus/prometheus.yml \
                            --storage.tsdb.path=/prometheus \
                            --storage.tsdb.retention.time=15d \
                            --web.enable-lifecycle --web.enable-admin-api || echo "Prometheus 启动失败"

                        echo ">>> 启动 Alertmanager..."
                        docker run -d --name lab-alertmanager --restart always --network lab-network --network-alias alertmanager \
                            -p 9093:9093 \
                            -v /opt/lab-monitor/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro \
                            -v lab-alertmanager-data:/alertmanager \
                            prom/alertmanager:v0.25.0 \
                            --config.file=/etc/alertmanager/alertmanager.yml \
                            --storage.path=/alertmanager || echo "Alertmanager 启动失败"

                        echo ">>> 启动 Loki..."
                        docker run -d --name lab-loki --restart always --network lab-network --network-alias loki \
                            -p 3100:3100 \
                            -v /opt/lab-monitor/loki/loki-config.yml:/etc/loki/local-config.yaml:ro \
                            -v /opt/lab-monitor/loki/rules:/loki/rules:ro \
                            -v lab-loki-data:/loki \
                            grafana/loki:2.9.0 -config.file=/etc/loki/local-config.yaml || echo "Loki 启动失败"

                        echo ">>> 启动 Promtail..."
                        docker run -d --name lab-promtail --restart always --network lab-network --network-alias promtail \
                            -v /opt/lab-monitor/promtail/promtail-config.yml:/etc/promtail/config.yml:ro \
                            -v /var/log:/var/log:ro \
                            -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
                            -v /var/run/docker.sock:/var/run/docker.sock:ro \
                            grafana/promtail:2.9.0 -config.file=/etc/promtail/config.yml || echo "Promtail 启动失败"

                        echo ">>> 启动 Grafana..."
                        docker run -d --name lab-grafana --restart always --network lab-network --network-alias grafana \
                            -p 3001:3001 \
                            -v /opt/lab-monitor/grafana/grafana.ini:/etc/grafana/grafana.ini:ro \
                            -v /opt/lab-monitor/grafana/provisioning:/etc/grafana/provisioning:ro \
                            -v lab-grafana-data:/var/lib/grafana \
                            -e GF_SECURITY_ADMIN_USER=admin \
                            -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
                            -e GF_USERS_ALLOW_SIGN_UP=false \
                            -e GF_INSTALL_PLUGINS=redis-datasource \
                            grafana/grafana:10.0.0 || echo "Grafana 启动失败"

                        echo ">>> 启动 Node Exporter..."
                        docker run -d --name lab-node-exporter --restart always --network lab-network --network-alias node-exporter \
                            -p 9100:9100 \
                            -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /:/rootfs:ro \
                            prom/node-exporter:v1.6.0 \
                            --path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs \
                            --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc)($|/)' || echo "Node Exporter 启动失败"

                        echo ">>> 启动 Blackbox Exporter..."
                        docker run -d --name lab-blackbox-exporter --restart always --network lab-network --network-alias blackbox-exporter \
                            -p 9115:9115 \
                            -v /opt/lab-monitor/blackbox/blackbox.yml:/etc/blackbox_exporter/config.yml:ro \
                            prom/blackbox-exporter:v0.24.0 || echo "Blackbox Exporter 启动失败"

                        echo ">>> 启动 MySQL Exporter..."
                        docker run -d --name lab-mysql-exporter --restart always --network lab-network --network-alias mysql-exporter \
                            -p 9104:9104 \
                            -e DATA_SOURCE_NAME="root:${MYSQL_ROOT_PASSWORD}@tcp(mysql:3306)/" \
                            prom/mysqld-exporter:v0.14.0 || echo "MySQL Exporter 启动失败"

                        echo ">>> 启动 Redis Exporter..."
                        docker run -d --name lab-redis-exporter --restart always --network lab-network --network-alias redis-exporter \
                            -p 9121:9121 \
                            -e REDIS_ADDR=redis://redis:6379 \
                            oliver006/redis_exporter:v1.50.0 || echo "Redis Exporter 启动失败"

                        echo "========================================"
                        echo "  监控系统部署完成"
                        echo "  Grafana:  http://${HOST}:3001 (admin / admin123)"
                        echo "  Prometheus: http://${HOST}:9090"
                        echo "========================================"
                    fi
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
                    sleep 45
                    for i in $(seq 1 20); do
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
