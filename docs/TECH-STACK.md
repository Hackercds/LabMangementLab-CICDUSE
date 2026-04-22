# 项目技术栈总结

## 📊 技术选型一览

### 前端技术栈

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Vue.js | 3.2 | 前端框架 | 渐进式JavaScript框架 |
| Element Plus | 2.2 | UI组件库 | 基于Vue 3的企业级组件库 |
| Pinia | 2.0 | 状态管理 | Vue官方推荐状态管理库 |
| Vue Router | 4.0 | 路由管理 | Vue官方路由 |
| Axios | 1.4 | HTTP客户端 | Promise based HTTP client |
| Vite | 4.0 | 构建工具 | 下一代前端构建工具 |
| ECharts | 5.4 | 图表库 | 数据可视化 |

### 后端技术栈

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Spring Boot | 2.7.0 | 后端框架 | 简化Spring应用开发 |
| Spring Security | 2.7.0 | 安全框架 | 认证授权 |
| MyBatis-Plus | 3.5.2 | ORM框架 | 增强版MyBatis |
| JWT | 0.11.5 | 认证方案 | JSON Web Token |
| Lombok | 1.18.28 | 代码简化 | 减少样板代码 |
| Hutool | 5.8.20 | 工具库 | Java工具集 |
| Knife4j | 3.0.3 | API文档 | Swagger增强UI |

### 数据存储

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| MySQL | 8.0 | 关系数据库 | 主数据存储 |
| Redis | 7.0 | 缓存数据库 | 缓存、会话存储 |
| Druid | 1.2.18 | 连接池 | 数据库连接池 |

### 测试技术栈

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Pytest | 7.4 | 测试框架 | Python测试框架 |
| Allure | 2.2 | 测试报告 | 测试报告生成 |
| Playwright | 1.40 | E2E测试 | 端到端测试 |
| Requests | 2.31 | HTTP测试 | API测试 |
| Locust | 2.17 | 性能测试 | 负载测试 |

### 容器与部署

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Docker | 24.0 | 容器化 | 应用容器化 |
| Docker Compose | 2.20 | 编排工具 | 多容器编排 |
| Nginx | 1.24 | 反向代理 | Web服务器 |

### 监控技术栈

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Prometheus | 2.45 | 指标采集 | 监控系统 |
| Grafana | 10.0 | 可视化 | 监控面板 |
| Loki | 2.9 | 日志聚合 | 日志系统 |
| Promtail | 2.9 | 日志采集 | 日志代理 |
| Alertmanager | 0.25 | 告警管理 | 告警通知 |
| cAdvisor | 0.47 | 容器监控 | Docker监控 |
| Node Exporter | 1.6 | 系统监控 | 主机监控 |

### CI/CD技术栈

| 技术 | 版本 | 用途 | 说明 |
|------|------|------|------|
| Jenkins | 2.4 | CI/CD | 持续集成 |
| GitLab CI | latest | CI/CD | GitLab流水线 |
| GitHub Actions | latest | CI/CD | GitHub流水线 |

---

## 🔧 开发工具

### IDE推荐

| 工具 | 用途 | 说明 |
|------|------|------|
| IntelliJ IDEA | Java开发 | 后端开发IDE |
| VS Code | 前端开发 | 前端开发编辑器 |
| DataGrip | 数据库管理 | 数据库IDE |

### 版本控制

| 工具 | 用途 | 说明 |
|------|------|------|
| Git | 版本控制 | 分布式版本控制 |
| GitLab/GitHub | 代码托管 | 代码仓库 |

---

## 📦 依赖管理

### 后端依赖 (Maven)

```xml
<dependencies>
    <!-- Spring Boot -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
        <version>2.7.0</version>
    </dependency>
    
    <!-- Spring Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
        <version>2.7.0</version>
    </dependency>
    
    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-boot-starter</artifactId>
        <version>3.5.2</version>
    </dependency>
    
    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.11.5</version>
    </dependency>
    
    <!-- Redis -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
        <version>2.7.0</version>
    </dependency>
    
    <!-- MySQL -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>8.0.33</version>
    </dependency>
</dependencies>
```

### 前端依赖 (NPM)

```json
{
  "dependencies": {
    "vue": "^3.2.0",
    "element-plus": "^2.2.0",
    "pinia": "^2.0.0",
    "vue-router": "^4.0.0",
    "axios": "^1.4.0",
    "echarts": "^5.4.0"
  },
  "devDependencies": {
    "vite": "^4.0.0",
    "@vitejs/plugin-vue": "^4.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0"
  }
}
```

### 测试依赖 (Python)

```txt
pytest==7.4.0
allure-pytest==2.13.0
playwright==1.40.0
requests==2.31.0
locust==2.17.0
PyMySQL==1.1.0
redis==4.6.0
```

---

## 🏗️ 架构模式

### 后端架构

```
Controller Layer (控制器层)
    ↓
Service Layer (业务逻辑层)
    ↓
Repository Layer (数据访问层)
    ↓
Database (数据库层)
```

### 前端架构

```
Views (视图层)
    ↓
Components (组件层)
    ↓
Stores (状态管理层)
    ↓
API (接口层)
```

---

## 📐 设计模式

| 模式 | 应用场景 | 说明 |
|------|----------|------|
| MVC | 整体架构 | Model-View-Controller |
| Repository | 数据访问 | 数据访问抽象 |
| Factory | 对象创建 | Bean工厂 |
| Strategy | 业务逻辑 | 策略模式处理不同场景 |
| Observer | 事件处理 | Spring事件机制 |
| Decorator | 功能增强 | AOP切面 |
| Singleton | Bean管理 | Spring单例Bean |

---

## 🔐 安全技术

| 技术 | 用途 | 说明 |
|------|------|------|
| BCrypt | 密码加密 | 单向加密算法 |
| JWT | 身份认证 | 无状态认证 |
| CORS | 跨域控制 | 跨域资源共享 |
| CSRF | 跨站请求防护 | CSRF Token |
| XSS | 跨站脚本防护 | 输入过滤 |
| SQL注入防护 | 数据库安全 | 参数化查询 |

---

## 📈 性能优化

| 技术 | 用途 | 说明 |
|------|------|------|
| Redis缓存 | 数据缓存 | 减少数据库访问 |
| 连接池 | 连接管理 | Druid连接池 |
| 异步处理 | 并发处理 | @Async注解 |
| 分页查询 | 数据分页 | MyBatis-Plus分页 |
| 索引优化 | 数据库优化 | MySQL索引 |
| CDN加速 | 静态资源 | 前端资源加速 |

---

## 📊 监控指标

| 类型 | 指标 | 说明 |
|------|------|------|
| 应用指标 | JVM内存、GC、线程 | Java应用性能 |
| HTTP指标 | QPS、响应时间、错误率 | API性能 |
| 系统指标 | CPU、内存、磁盘、网络 | 服务器资源 |
| 业务指标 | 预约数、用户活跃度 | 业务数据 |
| 数据库指标 | 连接数、慢查询 | 数据库性能 |

---

## 🚀 版本规划

| 版本 | 功能 | 状态 |
|------|------|------|
| v1.0.0 | 基础功能 | ✅ 已完成 |
| v1.1.0 | 监控系统 | ✅ 已完成 |
| v1.2.0 | CI/CD集成 | ✅ 已完成 |
| v1.3.0 | 测试体系 | ✅ 已完成 |
| v2.0.0 | 微服务架构 | 📋 规划中 |

---

**文档维护**: Lab Management Team  
**最后更新**: 2024年
