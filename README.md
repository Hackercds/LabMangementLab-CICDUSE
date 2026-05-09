# 实验室管理系统

> 面向高校实验室资源管理的综合性平台，提供实验室预约、设备管理、耗材管理、公告发布等功能。

[![Java](https://img.shields.io/badge/Java-21-green.svg)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.0-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Vue](https://img.shields.io/badge/Vue-3.2-4FC08D.svg)](https://vuejs.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 目录

- [项目简介](#项目简介)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
- [核心功能](#核心功能)
- [测试体系](#测试体系)
- [CI/CD](#cicd)
- [监控系统](#监控系统)
- [部署指南](#部署指南)
- [配置说明](#配置说明)
- [文档中心](#文档中心)

---

## 项目简介

实验室管理系统是一个面向高校实验室资源管理的综合性平台，旨在解决实验室资源管理混乱、预约流程繁琐、信息不透明等问题。

### 特性

- **前后端分离**: Vue 3 + Spring Boot，架构清晰
- **安全认证**: JWT + Spring Security，安全可靠
- **多角色权限**: 管理员、教师、学生三级权限
- **完整测试**: 单元测试、API测试、E2E测试全覆盖
- **自动化部署**: Docker + Jenkins CI/CD，一键部署
- **全链路监控**: Prometheus + Grafana + Loki
- **高可用设计**: 重试、限流、熔断、降级

---

## 目录结构

```
lab-management-system/
│
├── backend/                        # 后端服务（Spring Boot）
│   ├── src/main/java/              # Java 源码
│   │   └── com/labmanagement/
│   │       ├── common/             # 通用组件（缓存/限流/重试/异常/健康检查）
│   │       ├── config/             # 应用配置类
│   │       ├── controller/         # REST 控制器
│   │       ├── entity/             # 数据实体
│   │       ├── mapper/             # MyBatis-Plus Mapper
│   │       ├── security/           # JWT 认证与权限
│   │       └── service/            # 业务逻辑层
│   ├── src/main/resources/
│   │   ├── db/schema.sql           # 数据库初始化脚本
│   │   ├── application.yml         # 主配置
│   │   ├── application-dev.yml     # 开发环境配置
│   │   ├── application-prod.yml    # 生产环境配置
│   │   └── application-test.yml    # 测试环境配置
│   ├── Dockerfile                  # 后端 Docker 镜像（多阶段构建）
│   └── pom.xml                     # Maven 依赖
│
├── frontend/                       # 前端服务（Vue 3）
│   ├── src/
│   │   ├── api/                    # API 请求封装
│   │   ├── views/                  # 页面组件
│   │   │   ├── admin/              # 管理员视图
│   │   │   ├── teacher/            # 教师视图
│   │   │   ├── student/            # 学生视图
│   │   │   └── login/              # 登录注册
│   │   ├── router/                 # 路由配置
│   │   ├── store/                  # Pinia 状态管理
│   │   ├── config/                 # 前端配置
│   │   └── utils/                  # 工具函数
│   ├── nginx.conf                  # Nginx 配置（生产环境）
│   ├── Dockerfile                  # 前端 Docker 镜像
│   ├── vite.config.js              # Vite 构建配置
│   └── package.json                # NPM 依赖
│
├── test/                           # 测试资源
│   ├── cypress/                    # E2E 测试（Cypress）
│   ├── jmeter/                     # 性能测试（JMeter）
│   └── postman/                    # API 测试（Postman Collection）
│
├── tests/                          # Python 自动化测试
│   ├── conftest.py                 # Pytest 配置与 Fixture
│   ├── test_auth.py                # 认证接口测试
│   ├── test_lab.py                 # 实验室接口测试
│   ├── test_reservation.py         # 预约接口测试
│   ├── requirements.txt            # Python 依赖
│   └── run_tests.py                # 测试执行入口
│
├── scripts/                        # 部署与运维脚本
│   ├── raw_start.bat / .ps1        # Windows裸机一键部署（小白用）
│   ├── init-deploy.bat / .sh       # Docker一键部署
│   ├── deploy.sh                   # 高级部署（含回滚）
│   ├── backup.sh                   # 数据备份
│   └── health-check.sh             # 健康检查
│
├── monitor/                        # 监控系统
│   ├── docker-compose.monitoring.yml
│   ├── monitor.sh / monitor.bat
│   ├── prometheus/
│   └── grafana/
├── docs/                           # 项目文档
│   ├── ARCHITECTURE.md             # 架构设计
│   ├── TECH-STACK.md               # 技术栈说明
│   ├── CONFIGURATION.md            # 配置详解
│   ├── CI-CD.md                    # CI/CD 文档
│   ├── RELIABILITY.md              # 可靠性设计
│   ├── QUICK-REFERENCE.md          # 快速参考卡
│   └── 详细设计文档.md              # 详细设计
│
├── .github/workflows/              # GitHub Actions CI
│
├── .env.example                    # 环境变量模板（复制为 .env 使用）
├── .gitignore                      # Git 忽略规则
├── Jenkinsfile                     # Jenkins CI/CD 流水线
├── docker-compose.yml              # Docker Compose 编排
├── deploy-docker.sh                # Docker 一键部署脚本
└── README.md                       # 项目说明
```

---

## 快速开始

### 环境要求

- JDK 21+
- Node.js 18+
- MySQL 8.0+
- Redis 7.0+
- Docker 24.0+

### 方式一：Docker 一键部署（推荐）

```bash
# 克隆项目
git clone http://192.168.3.2:3000/CICDUse/26-XCK.git
cd 26-XCK

# 配置环境变量
cp .env.example .env
# 编辑 .env 修改 HOST_IP 等配置

# 一键部署
bash deploy-docker.sh
```

### 方式二：Docker Compose

```bash
docker-compose up -d
```

### 方式三：本地开发

```bash
# 后端
cd backend
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"

# 前端
cd frontend
npm install
npm run dev
```

### 方式四：运维脚本

```bash
./scripts/start.sh all      # Linux
scripts\start.bat all       # Windows
```

---

## 核心功能

| 模块 | 功能 | 角色 |
|------|------|------|
| 用户管理 | 注册/登录/权限管理 | 全部 |
| 实验室管理 | 实验室信息维护/状态管理 | 管理员 |
| 设备管理 | 设备登记/借用/归还 | 管理员/教师 |
| 预约管理 | 预约申请/审批/取消 | 教师/学生 |
| 耗材管理 | 库存管理/出入库/预警 | 管理员 |
| 公告管理 | 发布/编辑/置顶 | 管理员 |
| 操作日志 | 全操作审计 | 管理员 |
| 数据统计 | 可视化数据面板 | 管理员 |

---

## 测试体系

```
┌─────────────────────────────────────────┐
│              测试金字塔                  │
├─────────────────────────────────────────┤
│         E2E 测试 (Cypress)              │
├─────────────────────────────────────────┤
│         集成测试 (Pytest)                │
├─────────────────────────────────────────┤
│         API 测试 (Postman)               │
├─────────────────────────────────────────┤
│         单元测试 (JUnit)                 │
└─────────────────────────────────────────┘
```

```bash
# Python 接口测试
cd tests
pip install -r requirements.txt
pytest --alluredir=reports/allure-results

# 性能测试
jmeter -n -t test/jmeter/实验室管理系统并发测试.jmx
```

---

## CI/CD

### Jenkins 流水线

```
代码检出 → Docker镜像构建 → 部署服务 → 健康检查
```

配置集中在 `Jenkinsfile` 的 `environment` 块中，修改 IP/端口/密码只需改一处。

### GitHub Actions

`.github/workflows/ci-cd.yml` 提供 PR 检查和自动构建。

---

## 监控系统

| 组件 | 端口 | 说明 |
|------|------|------|
| Prometheus | 9090 | 指标采集 |
| Grafana | 3001 | 可视化面板 |
| Loki | 3100 | 日志聚合 |
| Alertmanager | 9093 | 告警管理 |

```bash
# 启动监控
cd monitoring
./monitor.sh start

# 或在 .env 中设 MONITOR_ENABLED=true，运行部署脚本自动部署
```

---

## 部署指南

### Docker 部署

```bash
# 配置环境变量
cp .env.example .env
vim .env    # 修改 HOST_IP、端口、密码等

# 一键部署
bash deploy-docker.sh
```

### 服务管理

```bash
./scripts/service.sh start all       # 启动所有
./scripts/service.sh stop all        # 停止所有
./scripts/service.sh restart backend # 重启后端
./scripts/service.sh status          # 查看状态
./scripts/service.sh logs backend    # 查看日志
```

---

## 配置说明

所有部署配置集中在 `.env` 文件（从 `.env.example` 复制），主要配置项：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `HOST_IP` | 192.168.3.55 | 部署主机 IP（组件间通信） |
| `BACKEND_PORT` | 8081 | 后端服务端口 |
| `FRONTEND_PORT` | 80 | 前端服务端口 |
| `MYSQL_ROOT_PASSWORD` | root123456 | MySQL root 密码 |
| `MYSQL_DATABASE` | lab_management | 数据库名 |
| `JWT_SECRET` | lab-management-... | JWT 签名密钥 |

换环境部署只需修改 `.env` 中的 `HOST_IP` 即可。

---

## 文档中心

| 文档 | 说明 |
|------|------|
| [架构文档](docs/ARCHITECTURE.md) | 系统架构设计 |
| [技术栈](docs/TECH-STACK.md) | 技术选型说明 |
| [配置说明](docs/CONFIGURATION.md) | 配置参数详解 |
| [可靠性设计](docs/RELIABILITY.md) | 高可用设计 |
| [CI/CD文档](docs/CI-CD.md) | 流水线配置 |
| [快速参考](docs/QUICK-REFERENCE.md) | 常用命令速查 |
| [小白指南](docs/小白指南.md) | 零基础使用教程 |

---

## 常见问题

**端口被占用**：修改 `.env` 或 `scripts/deploy.conf` 中的端口配置。

**数据库连接失败**：检查 MySQL 是否启动，确认 `.env` 中密码配置正确。

**前端无法访问后端 API**：检查 `frontend/nginx.conf` 中 `proxy_pass` 地址是否正确。

**Docker 容器启动失败**：查看日志 `docker logs lab-backend`。

---

**Made with ❤️ by Lab Management Team**
