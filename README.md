# 实验室管理系统

> 一个面向高校实验室资源管理的综合性平台，提供实验室预约、设备管理、耗材管理、公告发布等功能。

[![Java](https://img.shields.io/badge/Java-11+-green.svg)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-2.7.0-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Vue](https://img.shields.io/badge/Vue-3.2-4FC08D.svg)](https://vuejs.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 目录

- [项目简介](#项目简介)
- [技术架构](#技术架构)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [核心功能](#核心功能)
- [测试体系](#测试体系)
- [CI/CD](#cicd)
- [监控系统](#监控系统)
- [部署指南](#部署指南)
- [开发指南](#开发指南)
- [文档中心](#文档中心)

---

## 项目简介

### 背景

实验室管理系统是一个面向高校实验室资源管理的综合性平台，旨在解决实验室资源管理混乱、预约流程繁琐、信息不透明等问题。

### 特性

- ✅ **前后端分离**: Vue 3 + Spring Boot，架构清晰
- ✅ **安全认证**: JWT + Spring Security，安全可靠
- ✅ **多角色权限**: 管理员、教师、学生三级权限
- ✅ **完整测试**: 单元测试、API测试、E2E测试全覆盖
- ✅ **自动化部署**: Docker + CI/CD，一键部署
- ✅ **全链路监控**: Prometheus + Grafana + Loki
- ✅ **高可用设计**: 重试、限流、熔断、降级

---

## 技术架构

### 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| **前端** | Vue 3 + Element Plus + Pinia | 3.2 / 2.2 / 2.0 |
| **后端** | Spring Boot + MyBatis-Plus | 2.7.0 / 3.5.2 |
| **数据库** | MySQL + Redis | 8.0 / 7.0 |
| **认证** | Spring Security + JWT | 2.7.0 |
| **容器** | Docker + Docker Compose | 24.0 |
| **监控** | Prometheus + Grafana + Loki | 2.45 / 10.0 / 2.9 |
| **测试** | Pytest + Allure + Playwright | 7.4 / 2.2 / 1.40 |
| **CI/CD** | Jenkins / GitLab CI / GitHub Actions | latest |

### 架构图

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   前端 Vue   │────▶│  后端 API   │────▶│   数据库    │
│  Element UI │     │ Spring Boot │     │   MySQL     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
             ┌──────────┐  ┌──────────┐
             │  Redis   │  │ 监控系统  │
             │  缓存    │  │Prometheus│
             └──────────┘  └──────────┘
```

---

## 快速开始

### 环境要求

- JDK 11+
- Node.js 18+
- MySQL 8.0+
- Redis 7.0+
- Docker & Docker Compose

### 方式一：Docker Compose（推荐）

```bash
# 克隆项目
git clone https://github.com/your-repo/lab-management-system.git
cd lab-management-system

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps
```

访问地址：
- 前端：http://localhost:3000
- 后端API：http://localhost:8081
- Grafana：http://localhost:3001

### 方式二：本地开发

#### 后端启动

```bash
cd backend

# 配置数据库
# 修改 src/main/resources/application-dev.yml

# 启动
mvn spring-boot:run
```

#### 前端启动

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

### 方式三：一键脚本

```bash
# Linux/macOS
./scripts/start.sh all

# Windows
scripts\start.bat all
```

---

## 项目结构

```
lab-management-system/
├── backend/                    # 后端服务
│   ├── src/main/java/         # Java源码
│   ├── src/main/resources/    # 配置文件
│   └── Dockerfile             # Docker构建
│
├── frontend/                   # 前端服务
│   ├── src/                   # Vue源码
│   ├── public/                # 静态资源
│   └── Dockerfile             # Docker构建
│
├── tests/                      # 测试套件
│   ├── test_*.py              # 测试用例
│   ├── conftest.py            # Pytest配置
│   └── run_tests.py           # 测试脚本
│
├── scripts/                    # 运维脚本
│   ├── start.sh/bat           # 启动脚本
│   ├── stop.sh/bat            # 停止脚本
│   ├── restart.sh/bat         # 重启脚本
│   ├── daemon.sh              # 守护进程
│   └── deploy.sh              # 部署脚本
│
├── monitoring/                 # 监控系统
│   ├── prometheus/            # Prometheus配置
│   ├── grafana/               # Grafana配置
│   ├── loki/                  # Loki日志
│   └── docker-compose.yml     # 监控Docker
│
├── monitoring-system/          # 独立监控系统
│   ├── quick-start.sh/bat     # 快速启动
│   └── README.md              # 使用文档
│
├── docs/                       # 项目文档
│   ├── ARCHITECTURE.md        # 架构文档
│   ├── CONFIGURATION.md       # 配置说明
│   └── CI-CD.md               # CI/CD文档
│
├── docker-compose.yml          # 开发环境
├── docker-compose.prod.yml     # 生产环境
├── Jenkinsfile                 # Jenkins流水线
└── README.md                   # 项目说明
```

---

## 核心功能

### 用户管理
- 用户注册、登录、信息管理
- 角色权限管理（管理员、教师、学生）
- JWT认证授权

### 实验室管理
- 实验室信息维护
- 设备管理
- 开放时间设置

### 预约管理
- 实验室预约申请
- 预约审批流程
- 预约记录查询

### 公告管理
- 公告发布、编辑、删除
- 公告置顶
- 公告分类

### 耗材管理
- 耗材库存管理
- 领用申请审批
- 库存预警

---

## 测试体系

### 测试类型

```
┌─────────────────────────────────────────┐
│              测试金字塔                  │
├─────────────────────────────────────────┤
│         E2E测试 (Playwright)            │
├─────────────────────────────────────────┤
│         集成测试 (Pytest)                │
├─────────────────────────────────────────┤
│         API测试 (REST)                   │
├─────────────────────────────────────────┤
│         单元测试 (JUnit)                 │
└─────────────────────────────────────────┘
```

### 运行测试

```bash
# 运行所有测试
pytest

# 运行冒烟测试
pytest -m smoke

# 运行API测试
pytest -m api

# 生成Allure报告
pytest --alluredir=reports/allure-results
allure serve reports/allure-results
```

---

## CI/CD

### 流水线阶段

```
代码提交 → 代码检查 → 单元测试 → 构建镜像 → 部署 → 冒烟测试
```

### 支持平台

- **Jenkins**: 使用 `Jenkinsfile`
- **GitLab CI**: 使用 `.gitlab-ci.yml`
- **GitHub Actions**: 使用 `.github/workflows/ci-cd.yml`

### 触发条件

- `main` 分支推送触发完整流水线
- Pull Request触发代码检查和单元测试
- 手动触发部署

---

## 监控系统

### 监控组件

| 组件 | 端口 | 说明 |
|------|------|------|
| Prometheus | 9090 | 指标采集 |
| Grafana | 3001 | 可视化面板 |
| Loki | 3100 | 日志聚合 |
| Alertmanager | 9093 | 告警管理 |

### 启动监控

```bash
# 进入监控目录
cd monitoring

# 启动
./monitor.sh start    # Linux
monitor.bat start     # Windows

# 或使用独立监控系统
cd monitoring-system
./quick-start.sh
```

### Dashboard

- 服务监控面板
- 系统资源监控
- 日志搜索分析
- JVM监控

---

## 部署指南

### 开发环境

```bash
docker-compose up -d
```

### 生产环境

```bash
# 配置环境变量
cp .env.example .env
vim .env

# 启动
docker-compose -f docker-compose.prod.yml up -d
```

### 服务管理

```bash
# 启动所有服务
./scripts/service.sh start all

# 停止所有服务
./scripts/service.sh stop all

# 重启服务
./scripts/service.sh restart backend

# 查看状态
./scripts/service.sh status

# 查看日志
./scripts/service.sh logs backend
```

---

## 开发指南

### 后端开发

```bash
cd backend

# 运行开发模式
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"

# 打包
mvn clean package -DskipTests

# 运行测试
mvn test
```

### 前端开发

```bash
cd frontend

# 安装依赖
npm install

# 开发模式
npm run dev

# 构建生产版本
npm run build

# 代码检查
npm run lint
```

### 代码规范

- 后端：遵循阿里巴巴Java开发规范
- 前端：ESLint + Prettier
- 提交：Conventional Commits

---

## 文档中心

| 文档 | 说明 |
|------|------|
| [架构文档](docs/ARCHITECTURE.md) | 系统架构设计 |
| [配置说明](docs/CONFIGURATION.md) | 配置参数详解 |
| [可靠性设计](docs/RELIABILITY.md) | 高可用设计 |
| [CI/CD文档](docs/CI-CD.md) | 流水线配置 |
| [监控系统](monitoring-system/README.md) | 独立监控系统 |

---

## 常见问题

### 1. 端口被占用
修改 `docker-compose.yml` 或 `scripts/deploy.conf` 中的端口配置。

### 2. 数据库连接失败
检查MySQL是否启动，确认配置文件中的连接信息正确。

### 3. 前端无法访问后端API
检查后端是否启动，确认CORS配置正确。

### 4. Docker容器启动失败
查看日志 `docker-compose logs [服务名]`，检查配置。

---

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 联系方式

- 项目地址: https://github.com/your-repo/lab-management-system
- 问题反馈: https://github.com/your-repo/lab-management-system/issues

---

**Made with ❤️ by Lab Management Team**
