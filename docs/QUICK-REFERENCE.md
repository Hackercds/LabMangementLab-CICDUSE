# 快速参考卡片

> 开发人员常用命令和配置速查表

---

## 🚀 快速启动命令

### 服务管理

```bash
# 一键启动所有服务
./scripts/start.sh all              # Linux/macOS
scripts\start.bat all               # Windows

# 启动单个服务
./scripts/start.sh backend          # 启动后端
./scripts/start.sh frontend         # 启动前端
./scripts/start.sh backend-dev      # 开发模式启动后端

# 停止服务
./scripts/stop.sh all               # 停止所有
./scripts/stop.sh backend           # 停止后端

# 重启服务
./scripts/restart.sh all            # 重启所有
./scripts/restart.sh graceful       # 优雅重启

# 查看状态
./scripts/service.sh status         # 服务状态
./scripts/service.sh health         # 健康检查
./scripts/service.sh logs backend   # 查看日志
```

### Docker命令

```bash
# 启动所有容器
docker-compose up -d

# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f backend
docker-compose logs -f --tail=100 frontend

# 重启容器
docker-compose restart backend

# 停止并删除
docker-compose down

# 重新构建
docker-compose up -d --build
```

### 监控系统

```bash
# 启动监控
cd monitor && ./monitor.sh start

# 停止监控
cd monitor && ./monitor.sh stop
```

---

## 🧪 测试命令

### Pytest测试

```bash
# 运行所有测试
pytest

# 运行指定类型
pytest -m smoke              # 冒烟测试
pytest -m api                # API测试
pytest -m e2e                # E2E测试
pytest -m "not slow"         # 排除慢测试

# 运行指定文件
pytest tests/test_auth.py
pytest tests/test_reservation.py

# 详细输出
pytest -v
pytest -vv                   # 更详细

# 生成覆盖率
pytest --cov=. --cov-report=html

# 生成Allure报告
pytest --alluredir=reports/allure-results
allure serve reports/allure-results
```

### 后端测试

```bash
cd backend

# 运行所有测试
mvn test

# 运行指定测试类
mvn test -Dtest=UserServiceTest

# 跳过测试打包
mvn package -DskipTests

# 生成测试报告
mvn surefire-report:report
```

### 前端测试

```bash
cd frontend

# 运行单元测试
npm run test

# 运行E2E测试
npm run test:e2e

# 测试覆盖率
npm run test:coverage
```

### JMeter 性能测试

```bash
cd test/jmeter

# 命令行模式（正式压测，生成 HTML 报告）
jmeter -n -t 实验室管理系统综合性能测试.jmx -l result.jtl -e -o report/

# GUI 模式（编辑/调试）
jmeter -t 实验室管理系统综合性能测试.jmx
```

测试覆盖：7 个线程组，500 并发 × 600s，JWT 鉴权，预约/设备/审批竞态，260 RPS/接口目标。

---

## 📦 构建命令

### 后端构建

```bash
cd backend

# 编译
mvn compile

# 打包
mvn package

# 打包跳过测试
mvn package -DskipTests

# 清理并打包
mvn clean package

# 安装到本地仓库
mvn install

# 运行
mvn spring-boot:run

# 指定环境运行
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"
```

### 前端构建

```bash
cd frontend

# 安装依赖
npm install

# 开发模式
npm run dev

# 构建生产版本
npm run build

# 预览生产版本
npm run preview

# 代码检查
npm run lint

# 代码格式化
npm run format
```

### Docker构建

```bash
# 构建镜像
docker build -t lab-management-backend:latest ./backend
docker build -t lab-management-frontend:latest ./frontend

# 使用docker-compose构建
docker-compose build

# 构建不使用缓存
docker-compose build --no-cache
```

---

## 🗄️ 数据库命令

### MySQL

```bash
# 连接数据库
mysql -u root -p

# 创建数据库
CREATE DATABASE lab_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 导入数据
mysql -u root -p lab_management < backup.sql

# 导出数据
mysqldump -u root -p lab_management > backup.sql

# 导出结构
mysqldump -u root -p --no-data lab_management > schema.sql
```

### Redis

```bash
# 连接Redis
redis-cli

# 连接指定主机和端口
redis-cli -h localhost -p 6379

# 清空缓存
redis-cli FLUSHALL

# 查看所有key
redis-cli KEYS "*"

# 查看key数量
redis-cli DBSIZE
```

---

## 📝 配置文件位置

| 配置文件 | 路径 | 说明 |
|----------|------|------|
| 后端配置 | `backend/src/main/resources/application.yml` | 唯一配置文件（含dev/test/prod） |
| 前端环境变量 | `frontend/.env.development` / `.env.production` | 前端环境变量 |
| Docker配置 | `docker-compose.yml` | Docker编排 |
| Prometheus | `monitor/prometheus/prometheus.yml` | 监控配置 |
| Grafana | `monitor/grafana/grafana.ini` | 可视化配置 |

---

## 🔧 常用端口

| 服务 | 端口 | 说明 |
|------|------|------|
| 后端API | 8081 | Spring Boot |
| 前端开发 | 3000 | Vite Dev Server |
| MySQL | 3306 | 数据库 |
| Redis | 6379 | 缓存 |
| Prometheus | 9090 | 监控 |
| Grafana | 3001 | 可视化 |
| Loki | 3100 | 日志 |
| Alertmanager | 9093 | 告警 |
| cAdvisor | 8080 | 容器监控 |
| mysql-exporter | 9104 | MySQL 指标导出 |
| redis-exporter | 9121 | Redis 指标导出 |

---

## 🌐 访问地址

### 开发环境

| 服务 | 地址 |
|------|------|
| 前端 | http://localhost:3000 |
| 后端API | http://localhost:8081 |
| API文档 | http://localhost:8081/doc.html |
| 健康检查 | http://localhost:8081/api/actuator/health |

### 监控系统

| 服务 | 地址 | 账号 |
|------|------|------|
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3001 | admin/admin123 |
| Alertmanager | http://localhost:9093 | - |
| cAdvisor | http://localhost:8080 | - |
| mysql-exporter | http://localhost:9104/metrics | Prometheus 抓取 |
| redis-exporter | http://localhost:9121/metrics | Prometheus 抓取 |

---

## 🐛 故障排查

### 查看日志

```bash
# 后端日志
tail -f logs/backend.log
docker-compose logs -f backend

# 前端日志
docker-compose logs -f frontend

# 所有日志
docker-compose logs -f

# 监控日志
tail -f monitor/logs/monitor.log
```

### 常见问题

```bash
# 端口被占用
lsof -i :8081                    # 查看端口占用
kill -9 <PID>                    # 终止进程

# Docker问题
docker-compose down              # 停止并删除
docker system prune -a           # 清理未使用资源

# 数据库连接失败
# 检查MySQL是否启动
docker-compose ps mysql
# 检查配置
cat backend/src/main/resources/application-dev.yml

# Redis连接失败
redis-cli ping                   # 测试连接
```

---

## 📋 Git命令

```bash
# 克隆项目
git clone https://github.com/your-repo/lab-management-system.git

# 创建分支
git checkout -b feature/new-feature

# 提交代码
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 更新代码
git pull origin main

# 查看状态
git status
git log --oneline -10
```

---

## 🔐 默认账号

> **注意：以下为默认示例。生产环境请务必修改密码！**

| 系统 | 用户名 | 密码 | 说明 |
|------|--------|------|------|
| 管理员 | admin | admin123 | 系统管理员（默认，可修改） |
| Grafana | admin | 见配置 | 监控面板（按 grafana.ini 中设置） |
| MySQL | root | 见 .env | 数据库（MYSQL_ROOT_PASSWORD） |
| Redis | - | 见 .env | 默认无密码 |

---

## 联系方式

- **文档中心**: docs/

---

**最后更新**: 2026-05-10
