# 实验室管理系统

> 高校实验室资源管理平台 — 预约、设备、耗材、公告一站式管理

[![Java 21](https://img.shields.io/badge/Java-21-green)](https://adoptium.net/)
[![Spring Boot 3](https://img.shields.io/badge/Spring_Boot-3.0-brightgreen)](https://spring.io/)
[![Vue 3](https://img.shields.io/badge/Vue-3.2-4FC08D)](https://vuejs.org/)
[![MySQL 8](https://img.shields.io/badge/MySQL-8.0-blue)](https://mysql.com/)

---

## 系统架构

```
浏览器 (Vue3 + Element Plus)
    │  HTTP /api/*
    ▼
Nginx (前端静态文件 + API反向代理)
    │  proxy_pass http://backend:8081
    ▼
Spring Boot 3 (REST API)
    │  MyBatis-Plus
    ├──▶ MySQL 8.0 (用户/实验室/设备/预约/耗材/日志/公告)
    │
    └──▶ Redis 7 (接口限流计数器 + 监控指标暂存)
           └── 非核心依赖，不可用时系统仍正常运行

监控链路 (可选):
  后端 /actuator/prometheus → Prometheus → Grafana 仪表盘
  容器日志 → Promtail → Loki → Grafana 日志查询
```

### 各组件职责

| 组件 | 作用 | 必须 |
|------|------|------|
| **MySQL** | 所有业务数据持久化 | 必须 |
| **Redis** | API 限流计数器、监控指标暂存、通用缓存 | 可选(不可用时限流失效) |
| **Nginx** | 前端静态文件 + `/api/` 反向代理到后端 | 生产环境必须 |
| **Prometheus+Grafana** | 服务监控、JVM指标、系统资源 | 可选 |

---

## 快速开始

### 方式一：裸机运行（不需要 Docker）

```
双击 scripts\raw_start.bat  →  选 [1] 一键安装+部署
```

脚本自动检测/安装 Java21 + Node18+ + MySQL8 + Maven，然后编译启动前后端。

### 方式二：Docker 部署（推荐生产环境）

```bash
cp .env.example .env          # 编辑 .env 修改密码和IP
bash scripts/init-deploy.sh   # 一键构建+启动全部容器
```

Windows 双击 `scripts\init-deploy.bat`。

部署后自动启动：MySQL、Redis、后端(8081)、前端(80)。在 `.env` 中设 `MONITOR_ENABLED=true` 可同时部署 Grafana+Prometheus 监控。

### 方式三：Docker Compose（本地开发）

```bash
docker-compose up -d
```
Docker Compose 自动读取 `.env` 中的配置。

### 方式四：本地开发

```bash
# 后端 (需要本地 MySQL + Redis)
cd backend && mvn spring-boot:run

# 前端 (另一个终端)
cd frontend && npm install && npm run dev
```

---

## 配置

**只改一个文件：`.env`**（从 `.env.example` 复制），所有部署方式共用。

```bash
HOST_IP=192.168.3.55       # 部署主机IP
BACKEND_PORT=8081           # 后端端口
FRONTEND_PORT=80            # 前端端口
MYSQL_ROOT_PASSWORD=xxx     # MySQL密码
JWT_SECRET=xxx              # JWT密钥
MONITOR_ENABLED=false       # 设为true自动部署监控
```

---

## 目录结构

```
├── backend/                  # Spring Boot 3 + MyBatis-Plus
├── frontend/                 # Vue 3 + Element Plus + Vite
├── scripts/                  # 部署脚本
│   ├── raw_start.bat/.ps1    # Windows裸机部署（小白用）
│   ├── init-deploy.sh/.bat   # Docker一键部署
│   ├── backup.sh             # 数据备份
│   └── health-check.sh       # 健康检查
├── monitor/                  # Prometheus + Grafana + Loki
├── test/                     # Playwright + JMeter + Postman
├── docs/                     # 文档中心
├── .env.example              # 环境变量模板 → 复制为 .env
├── docker-compose.yml        # Docker Compose 编排
└── Jenkinsfile               # Jenkins CI/CD
```

---

## 核心功能

| 模块 | 功能 | 权限 |
|------|------|------|
| 用户管理 | 注册/登录/个人信息 | 全部 |
| 实验室管理 | 信息维护/状态管理 | 管理员 |
| 设备管理 | 登记/借用/归还（独立借用历史表） | 全部 |
| 预约管理 | 申请/冲突检测/审批（悲观锁防并发） | 教师+学生 |
| 耗材管理 | 库存管理/出入库/低库存预警 | 管理员 |
| 公告管理 | 发布/编辑/置顶 | 管理员 |
| 操作日志 | 全操作审计+前后数据快照 | 管理员 |
| 数据统计 | ECharts 可视化面板 | 管理员 |

---

## 测试

```bash
# Playwright 前端E2E (Chromium + Firefox + WebKit)
cd test/playwright && npm install && npx playwright install chromium && npx playwright test

# JMeter 性能测试
jmeter -n -t test/jmeter/实验室管理系统并发测试.jmx

# Postman API测试
# 导入 test/postman/实验室管理系统.postman_collection.json
```

---

## 文档

| 文档 | 说明 |
|------|------|
| [小白指南](docs/小白指南.md) | 零基础部署教程 |
| [架构设计](docs/ARCHITECTURE.md) | 系统架构 |
| [详细设计](docs/详细设计文档.md) | 数据库设计+接口文档 |
| [技术栈](docs/TECH-STACK.md) | 技术选型 |
| [配置说明](docs/CONFIGURATION.md) | 配置参数详解 |
| [快速参考](docs/QUICK-REFERENCE.md) | 常用命令 |
| [CI/CD](docs/CI-CD.md) | Jenkins流水线 |
