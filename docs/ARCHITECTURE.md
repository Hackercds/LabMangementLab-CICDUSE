# 实验室管理系统 - 项目架构文档

> 版本: 1.0.0  
> 架构师: Lab Management Team  
> 更新日期: 2024年

---

## 📋 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [目录结构](#3-目录结构)
4. [核心模块](#4-核心模块)
5. [测试体系](#5-测试体系)
6. [CI/CD流水线](#6-cicd流水线)
7. [监控系统](#7-监控系统)
8. [部署架构](#8-部署架构)
9. [运维手册](#9-运维手册)
10. [安全设计](#10-安全设计)

---

## 1. 项目概述

### 1.1 项目背景

实验室管理系统是一个面向高校实验室资源管理的综合性平台，提供实验室预约、设备管理、耗材管理、公告发布等功能。

### 1.2 技术栈总览

| 层级 | 技术选型 | 版本 |
|------|----------|------|
| **前端** | Vue 3 + Element Plus + Pinia + Vite | 3.2 / 2.2 / 2.0 / 4.0 |
| **后端** | Spring Boot + MyBatis-Plus + Spring Security | 2.7.0 / 3.5.2 |
| **数据库** | MySQL + Redis | 8.0 / 7.0 |
| **消息队列** | RabbitMQ (可选) | 3.12 |
| **容器化** | Docker + Docker Compose | 24.0 / 2.20 |
| **监控** | Prometheus + Grafana + Loki | 2.45 / 10.0 / 2.9 |
| **测试** | Pytest + Allure + Playwright | 7.4 / 2.2 / 1.40 |
| **CI/CD** | Jenkins / GitLab CI / GitHub Actions | 2.4 / latest |

### 1.3 系统特性

- ✅ 前后端分离架构
- ✅ RESTful API设计
- ✅ JWT认证授权
- ✅ 多环境配置支持
- ✅ 完整的测试体系
- ✅ 容器化部署
- ✅ 全链路监控
- ✅ 自动化CI/CD
- ✅ 高可用设计

---

## 2. 技术架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           用户层 (Client Layer)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Web端     │  │   移动端    │  │  第三方系统  │  │   管理后台   │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          接入层 (Gateway Layer)                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Nginx (反向代理 + 负载均衡)                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌───────────────────────┐ ┌───────────────┐ ┌───────────────┐
│    前端服务 (Vue)      │ │  后端服务      │ │  监控服务      │
│  ┌─────────────────┐  │ │  (Spring Boot) │ │ (Prometheus)  │
│  │   Static Files  │  │ │               │ │               │
│  │   Vite Dev      │  │ │  ┌─────────┐  │ │  ┌─────────┐  │
│  │   Element Plus  │  │ │  │  API    │  │ │  │Metrics  │  │
│  └─────────────────┘  │ │  │ Service │  │ │  │Alerts   │  │
│                       │ │  └─────────┘  │ │  └─────────┘  │
└───────────────────────┘ └───────────────┘ └───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          数据层 (Data Layer)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   MySQL     │  │   Redis     │  │  RabbitMQ   │  │    Loki     │   │
│  │  (主数据库)  │  │  (缓存)     │  │  (消息队列)  │  │  (日志存储)  │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 后端架构分层

```
┌─────────────────────────────────────────────────────────────────┐
│                      Controller Layer (控制器层)                  │
│  - 接收HTTP请求                                                  │
│  - 参数校验                                                      │
│  - 返回响应                                                      │
├─────────────────────────────────────────────────────────────────┤
│                      Service Layer (业务逻辑层)                   │
│  - 业务逻辑处理                                                  │
│  - 事务管理                                                      │
│  - 缓存处理                                                      │
├─────────────────────────────────────────────────────────────────┤
│                      Repository Layer (数据访问层)                │
│  - MyBatis-Plus Mapper                                          │
│  - 数据库操作                                                    │
├─────────────────────────────────────────────────────────────────┤
│                      Common Layer (公共组件层)                    │
│  - 异常处理 (GlobalExceptionHandler)                             │
│  - 重试机制 (RetryComponent)                                     │
│  - 限流组件 (RateLimitAspect)                                    │
│  - 缓存组件 (CacheComponent)                                     │
│  - 健康检查 (HealthIndicators)                                   │
│  - 监控组件 (MonitorComponent)                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 目录结构

```
lab-management-system/
├── backend/                          # 后端服务
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/labmanagement/
│   │   │   │   ├── config/           # 配置类
│   │   │   │   │   ├── SecurityConfig.java
│   │   │   │   │   ├── RedisConfig.java
│   │   │   │   │   ├── MyBatisPlusConfig.java
│   │   │   │   │   └── AppProperties.java
│   │   │   │   ├── controller/       # 控制器层
│   │   │   │   │   ├── AuthController.java
│   │   │   │   │   ├── UserController.java
│   │   │   │   │   ├── LabController.java
│   │   │   │   │   ├── ReservationController.java
│   │   │   │   │   └── ...
│   │   │   │   ├── service/          # 业务逻辑层
│   │   │   │   │   ├── impl/
│   │   │   │   │   └── ...
│   │   │   │   ├── mapper/           # 数据访问层
│   │   │   │   ├── entity/           # 实体类
│   │   │   │   ├── dto/              # 数据传输对象
│   │   │   │   ├── vo/               # 视图对象
│   │   │   │   ├── common/           # 公共组件
│   │   │   │   │   ├── exception/    # 异常处理
│   │   │   │   │   ├── retry/        # 重试组件
│   │   │   │   │   ├── ratelimit/    # 限流组件
│   │   │   │   │   ├── cache/        # 缓存组件
│   │   │   │   │   ├── trace/        # 链路追踪
│   │   │   │   │   ├── shutdown/     # 优雅停机
│   │   │   │   │   ├── health/       # 健康检查
│   │   │   │   │   ├── backup/       # 备份组件
│   │   │   │   │   └── monitor/      # 监控组件
│   │   │   │   ├── security/         # 安全模块
│   │   │   │   │   ├── JwtUtils.java
│   │   │   │   │   ├── JwtFilter.java
│   │   │   │   │   └── UserDetailsServiceImpl.java
│   │   │   │   └── LabManagementApplication.java
│   │   │   └── resources/
│   │   │       ├── application.yml        # 主配置
│   │   │       ├── application-dev.yml    # 开发环境
│   │   │       ├── application-test.yml   # 测试环境
│   │   │       ├── application-prod.yml   # 生产环境
│   │   │       └── mapper/                # MyBatis XML
│   │   └── test/                     # 单元测试
│   ├── Dockerfile                    # Docker构建文件
│   └── pom.xml                       # Maven配置
│
├── frontend/                         # 前端服务
│   ├── src/
│   │   ├── api/                      # API接口
│   │   ├── assets/                   # 静态资源
│   │   ├── components/               # 公共组件
│   │   ├── layouts/                  # 布局组件
│   │   ├── router/                   # 路由配置
│   │   ├── stores/                   # Pinia状态管理
│   │   ├── styles/                   # 样式文件
│   │   ├── utils/                    # 工具函数
│   │   └── views/                    # 页面组件
│   │       ├── admin/                # 管理员页面
│   │       ├── student/              # 学生页面
│   │       └── teacher/              # 教师页面
│   ├── public/                       # 公共资源
│   ├── .env.development              # 开发环境变量
│   ├── .env.test                     # 测试环境变量
│   ├── .env.production               # 生产环境变量
│   ├── Dockerfile                    # Docker构建文件
│   ├── vite.config.js                # Vite配置
│   └── package.json                  # NPM配置
│
├── tests/                            # 测试套件
│   ├── api/                          # API测试
│   ├── e2e/                          # 端到端测试
│   ├── performance/                  # 性能测试
│   ├── security/                     # 安全测试
│   ├── test_*.py                     # 测试用例
│   ├── conftest.py                   # Pytest配置
│   ├── pytest.ini                    # Pytest配置文件
│   ├── run_tests.py                  # 测试运行脚本
│   └── requirements.txt              # Python依赖
│
├── scripts/                          # 运维脚本
│   ├── deploy.conf                   # 部署配置
│   ├── deploy.conf.bat               # Windows部署配置
│   ├── start.sh / start.bat          # 一键启动
│   ├── stop.sh / stop.bat            # 一键停止
│   ├── restart.sh / restart.bat      # 一键重启
│   ├── daemon.sh                     # 守护进程
│   ├── service.sh / service.bat      # 服务管理
│   ├── deploy.sh                     # 自动化部署
│   ├── backup.sh                     # 备份脚本
│   ├── health-check.sh               # 健康检查
│   └── blue-green-deploy.sh          # 蓝绿部署
│
├── monitoring/                       # 监控系统
│   ├── prometheus/
│   │   ├── prometheus.yml            # Prometheus配置
│   │   └── alert_rules.yml           # 告警规则
│   ├── grafana/
│   │   ├── grafana.ini               # Grafana配置
│   │   └── provisioning/
│   │       ├── datasources/          # 数据源配置
│   │       └── dashboards/           # Dashboard配置
│   ├── alertmanager/
│   │   └── alertmanager.yml          # 告警管理配置
│   ├── loki/
│   │   ├── loki-config.yml           # Loki配置
│   │   └── rules/                    # 日志告警规则
│   ├── promtail/
│   │   └── promtail-config.yml       # Promtail配置
│   ├── blackbox/
│   │   └── blackbox.yml              # 黑盒探测配置
│   ├── docker-compose.monitoring.yml # 监控Docker配置
│   ├── monitor.sh / monitor.bat      # 监控启动脚本
│   └── dashboards/                   # Dashboard JSON文件
│
├── monitoring-system/                # 独立监控系统(可复用)
│   ├── setup.sh / setup.bat          # 完整管理脚本
│   ├── quick-start.sh / quick-start.bat  # 快速启动
│   └── README.md                     # 使用文档
│
├── docs/                             # 项目文档
│   ├── CONFIGURATION.md              # 配置说明
│   ├── RELIABILITY.md                # 可靠性设计
│   ├── CI-CD.md                      # CI/CD文档
│   ├── API.md                        # API文档
│   └── DEPLOYMENT.md                 # 部署文档
│
├── docker-compose.yml                # 开发环境Docker配置
├── docker-compose.prod.yml           # 生产环境Docker配置
├── Jenkinsfile                       # Jenkins流水线
├── .gitlab-ci.yml                    # GitLab CI配置
├── .github/workflows/ci-cd.yml       # GitHub Actions配置
├── README.md                         # 项目说明
└── .gitignore                        # Git忽略配置
```

---

## 4. 核心模块

### 4.1 认证授权模块

```
认证流程:
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  用户登录 │ ──▶ │ JWT生成  │ ──▶ │ Token存储 │ ──▶ │ 权限校验 │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                      │                                   │
                      ▼                                   ▼
               ┌──────────┐                      ┌──────────┐
               │ Redis缓存│                      │ 角色权限  │
               └──────────┘                      └──────────┘
```

**核心类:**
- `SecurityConfig`: Spring Security配置
- `JwtUtils`: JWT工具类
- `JwtFilter`: JWT过滤器
- `UserDetailsServiceImpl`: 用户详情服务

### 4.2 业务模块

| 模块 | 功能 | 核心类 |
|------|------|--------|
| 用户管理 | 用户CRUD、角色分配 | UserController, UserService |
| 实验室管理 | 实验室信息、设备管理 | LabController, LabService |
| 预约管理 | 预约申请、审批流程 | ReservationController, ReservationService |
| 公告管理 | 公告发布、置顶 | AnnouncementController, AnnouncementService |
| 耗材管理 | 耗材库存、领用 | ConsumableController, ConsumableService |

### 4.3 公共组件

```java
// 异常处理
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusinessException(BusinessException e) {
        return Result.error(e.getCode(), e.getMessage());
    }
}

// 重试组件
@Component
public class RetryComponent {
    @Retryable(maxAttempts = 3, backoff = @Backoff(delay = 1000))
    public <T> T execute(Supplier<T> supplier) {
        return supplier.get();
    }
}

// 限流组件
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimit {
    int value() default 100;
    int timeout() default 1;
}
```

---

## 5. 测试体系

### 5.1 测试金字塔

```
                    ┌─────────────┐
                    │   E2E测试   │  (10%)
                    │  Playwright │
                    ├─────────────┤
                    │  集成测试    │  (20%)
                    │   Pytest    │
                    ├─────────────┤
                    │  API测试    │  (30%)
                    │   REST      │
                    ├─────────────┤
                    │  单元测试    │  (40%)
                    │  JUnit/Mock │
                    └─────────────┘
```

### 5.2 测试目录结构

```
tests/
├── conftest.py                 # Pytest配置和Fixtures
├── test_auth.py                # 认证测试
├── test_user.py                # 用户测试
├── test_lab.py                 # 实验室测试
├── test_reservation.py         # 预约测试
├── test_announcement.py        # 公告测试
├── test_consumable.py          # 耗材测试
├── api/                        # API测试
│   ├── test_backend_api.py
│   └── test_frontend_api.py
├── e2e/                        # 端到端测试
│   ├── test_login_flow.py
│   └── test_reservation_flow.py
├── performance/                # 性能测试
│   ├── locustfile.py
│   └── stress_test.py
├── security/                   # 安全测试
│   ├── test_sql_injection.py
│   └── test_xss.py
├── reports/                    # 测试报告
│   └── allure-results/
├── run_tests.py                # 测试运行脚本
├── pytest.ini                  # Pytest配置
└── requirements.txt            # 依赖
```

### 5.3 测试命令

```bash
# 运行所有测试
pytest

# 运行指定类型测试
pytest -m smoke          # 冒烟测试
pytest -m api            # API测试
pytest -m e2e            # E2E测试
pytest -m performance    # 性能测试

# 生成Allure报告
pytest --alluredir=reports/allure-results
allure serve reports/allure-results
```

---

## 6. CI/CD流水线

### 6.1 流水线架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CI/CD Pipeline                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌───────┐│
│  │ 代码提交 │──▶│ 代码检查 │──▶│ 单元测试 │──▶│ 构建镜像 │──▶│ 部署  ││
│  │  Git    │   │ Lint    │   │  Test   │   │ Docker  │   │Deploy ││
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘   └───────┘│
│       │             │             │             │             │     │
│       ▼             ▼             ▼             ▼             ▼     │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌───────┐│
│  │ 触发构建 │   │ SonarQube│   │ Coverage│   │ Harbor  │   │ K8s   ││
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘   └───────┘│
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'harbor.example.com'
        IMAGE_NAME = 'lab-management'
    }
    
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        
        stage('Code Analysis') {
            steps { sh 'mvn sonar:sonar' }
        }
        
        stage('Unit Test') {
            steps { sh 'mvn test' }
            post { always { junit '**/target/surefire-reports/*.xml' } }
        }
        
        stage('Build') {
            steps { sh 'mvn package -DskipTests' }
        }
        
        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }
        
        stage('Deploy') {
            steps { sh './scripts/deploy.sh' }
        }
        
        stage('Smoke Test') {
            steps { sh 'pytest -m smoke' }
        }
    }
    
    post {
        success { notifySuccess() }
        failure { notifyFailure() }
    }
}
```

---

## 7. 监控系统

### 7.1 监控架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                        监控数据流                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │ Application │───▶│  Prometheus │───▶│   Grafana   │             │
│  │  Metrics    │    │   (存储)    │    │  (可视化)   │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│         │                  │                  │                      │
│         ▼                  ▼                  ▼                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │   Logs      │───▶│    Loki     │───▶│   Grafana   │             │
│  │ (Promtail)  │    │  (日志存储) │    │  (日志查询) │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│                            │                                         │
│                            ▼                                         │
│                     ┌─────────────┐                                  │
│                     │Alertmanager │                                  │
│                     │  (告警通知) │                                  │
│                     └─────────────┘                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 监控指标

| 类型 | 指标 | 说明 |
|------|------|------|
| **应用指标** | JVM内存、GC、线程数 | Java应用性能 |
| **HTTP指标** | 请求数、响应时间、错误率 | API性能 |
| **系统指标** | CPU、内存、磁盘、网络 | 服务器资源 |
| **业务指标** | 预约数、用户活跃度 | 业务数据 |
| **数据库指标** | 连接数、慢查询 | 数据库性能 |

### 7.3 告警规则

```yaml
groups:
  - name: critical_alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "服务宕机"
          
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
          
      - alert: HighMemoryUsage
        expr: jvm_memory_used_bytes / jvm_memory_max_bytes > 0.9
        for: 5m
        labels:
          severity: warning
```

---

## 8. 部署架构

### 8.1 环境规划

| 环境 | 用途 | 配置 |
|------|------|------|
| Development | 开发环境 | 本地Docker |
| Test | 测试环境 | 单机部署 |
| Staging | 预发布环境 | 与生产一致 |
| Production | 生产环境 | 集群部署 |

### 8.2 Docker Compose部署

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: ["./nginx.conf:/etc/nginx/nginx.conf"]
    
  backend:
    build: ./backend
    ports: ["8081:8081"]
    environment:
      - SPRING_PROFILES_ACTIVE=prod
    depends_on: [mysql, redis]
    
  frontend:
    build: ./frontend
    depends_on: [backend]
    
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_PASSWORD}
    volumes: ["mysql_data:/var/lib/mysql"]
    
  redis:
    image: redis:7-alpine
    volumes: ["redis_data:/data"]
```

### 8.3 Kubernetes部署 (生产环境)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-management-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    spec:
      containers:
      - name: backend
        image: lab-management-backend:latest
        ports:
        - containerPort: 8081
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

---

## 9. 运维手册

### 9.1 日常运维命令

```bash
# 服务管理
./scripts/service.sh start all      # 启动所有服务
./scripts/service.sh stop all       # 停止所有服务
./scripts/service.sh restart all    # 重启所有服务
./scripts/service.sh status         # 查看服务状态
./scripts/service.sh logs backend   # 查看后端日志

# 监控系统
./monitoring/monitor.sh start       # 启动监控
./monitoring/monitor.sh stop        # 停止监控
./monitoring/monitor.sh status      # 查看监控状态

# 部署
./scripts/deploy.sh                 # 执行部署
./scripts/backup.sh                 # 执行备份
./scripts/health-check.sh           # 健康检查

# 测试
pytest -m smoke                     # 冒烟测试
pytest --alluredir=reports          # 生成测试报告
```

### 9.2 故障排查

| 问题 | 排查步骤 | 解决方案 |
|------|----------|----------|
| 服务无法启动 | 检查端口占用、日志 | 释放端口、修复配置 |
| 数据库连接失败 | 检查MySQL状态、连接配置 | 重启MySQL、修正配置 |
| 内存溢出 | 查看JVM内存、GC日志 | 调整JVM参数 |
| 接口响应慢 | 查看APM、数据库慢查询 | 优化SQL、增加缓存 |

### 9.3 备份恢复

```bash
# 数据库备份
mysqldump -u root -p lab_management > backup_$(date +%Y%m%d).sql

# 数据库恢复
mysql -u root -p lab_management < backup_20240101.sql

# 配置备份
tar -czvf config_backup.tar.gz backend/src/main/resources/
```

---

## 10. 安全设计

### 10.1 安全架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                          安全层级                                    │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    网络安全层                                 │   │
│  │  - HTTPS/TLS                                                 │   │
│  │  - 防火墙规则                                                 │   │
│  │  - DDoS防护                                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    应用安全层                                 │   │
│  │  - JWT认证                                                   │   │
│  │  - RBAC权限控制                                              │   │
│  │  - 接口限流                                                  │   │
│  │  - 参数校验                                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    数据安全层                                 │   │
│  │  - 密码加密存储                                               │   │
│  │  - SQL注入防护                                               │   │
│  │  - XSS防护                                                   │   │
│  │  - 敏感数据脱敏                                               │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 10.2 安全配置

```java
// 密码加密
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}

// CSRF防护
http.csrf().csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse());

// CORS配置
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("https://example.com"));
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE"));
    return new UrlBasedCorsConfigurationSource();
}
```

---

## 附录

### A. 配置参数说明

详见: [CONFIGURATION.md](docs/CONFIGURATION.md)

### B. API接口文档

详见: [API.md](docs/API.md)

### C. 部署指南

详见: [DEPLOYMENT.md](docs/DEPLOYMENT.md)

### D. 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1.0.0 | 2024-01 | 初始版本发布 |

---

**文档维护**: Lab Management Team  
**最后更新**: 2024年
