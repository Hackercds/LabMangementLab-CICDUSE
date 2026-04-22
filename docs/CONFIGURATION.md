# 配置参数说明文档

## 📋 概述

本文档详细说明了实验室管理系统的所有配置参数，包括后端配置和前端配置。

## 🔧 后端配置

### 1. 应用配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 应用名称 | SPRING_APPLICATION_NAME | lab-management | Spring应用名称 |
| 运行环境 | SPRING_PROFILES_ACTIVE | dev | 运行环境：dev/test/prod |
| 应用标题 | APP_NAME | 实验室管理系统 | 应用显示名称 |
| 应用版本 | APP_VERSION | 1.0.0 | 应用版本号 |
| 应用描述 | APP_DESCRIPTION | 实验室管理系统API | 应用描述 |

### 2. 服务器配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 服务端口 | SERVER_PORT | 8081 | HTTP服务端口 |
| 上下文路径 | SERVER_CONTEXT_PATH | /api | 应用上下文路径 |
| 最大线程数 | SERVER_MAX_THREADS | 200 | Tomcat最大线程数 |
| 最小线程数 | SERVER_MIN_THREADS | 10 | Tomcat最小线程数 |
| 等待队列长度 | SERVER_ACCEPT_COUNT | 100 | 等待队列长度 |
| 最大连接数 | SERVER_MAX_CONNECTIONS | 10000 | 最大连接数 |
| 连接超时时间 | SERVER_CONNECTION_TIMEOUT | 5000 | 连接超时时间（毫秒） |

### 3. 数据库配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 数据库主机 | DB_HOST | localhost | 数据库主机地址 |
| 数据库端口 | DB_PORT | 3306 | 数据库端口 |
| 数据库名称 | DB_NAME | lab_management | 数据库名称 |
| 数据库用户名 | DB_USERNAME | root | 数据库用户名 |
| 数据库密码 | DB_PASSWORD | - | 数据库密码 |

#### 连接池配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最小空闲连接数 | DB_POOL_MIN_IDLE | 5 | 最小空闲连接数 |
| 最大连接数 | DB_POOL_MAX_SIZE | 20 | 最大连接数 |
| 空闲超时时间 | DB_POOL_IDLE_TIMEOUT | 600000 | 空闲超时时间（毫秒） |
| 最大生命周期 | DB_POOL_MAX_LIFETIME | 1800000 | 连接最大生命周期（毫秒） |
| 连接超时时间 | DB_POOL_CONNECTION_TIMEOUT | 30000 | 连接超时时间（毫秒） |

### 4. Redis配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| Redis主机 | REDIS_HOST | localhost | Redis主机地址 |
| Redis端口 | REDIS_PORT | 6379 | Redis端口 |
| Redis密码 | REDIS_PASSWORD | - | Redis密码 |
| Redis数据库 | REDIS_DATABASE | 0 | Redis数据库索引 |
| 连接超时时间 | REDIS_TIMEOUT | 5000 | 连接超时时间（毫秒） |

#### Redis连接池配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最大活跃连接数 | REDIS_POOL_MAX_ACTIVE | 8 | 最大活跃连接数 |
| 最大空闲连接数 | REDIS_POOL_MAX_IDLE | 8 | 最大空闲连接数 |
| 最小空闲连接数 | REDIS_POOL_MIN_IDLE | 0 | 最小空闲连接数 |
| 最大等待时间 | REDIS_POOL_MAX_WAIT | -1 | 最大等待时间（毫秒） |

### 5. JWT配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| JWT密钥 | JWT_SECRET | - | JWT签名密钥 |
| JWT过期时间 | JWT_EXPIRATION | 86400000 | JWT过期时间（毫秒） |
| JWT请求头 | JWT_HEADER | Authorization | JWT请求头名称 |
| JWT前缀 | JWT_PREFIX | Bearer | JWT令牌前缀 |
| JWT签发者 | JWT_ISSUER | lab-management | JWT签发者 |

### 6. 日志配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 根日志级别 | LOG_LEVEL_ROOT | info | 根日志级别 |
| 应用日志级别 | LOG_LEVEL_APP | debug | 应用日志级别 |
| Spring日志级别 | LOG_LEVEL_SPRING | info | Spring框架日志级别 |
| MyBatis日志级别 | LOG_LEVEL_MYBATIS | info | MyBatis日志级别 |
| Hikari日志级别 | LOG_LEVEL_HIKARI | info | HikariCP日志级别 |
| 日志文件名 | LOG_FILE_NAME | logs/lab-management.log | 日志文件路径 |
| 日志文件最大大小 | LOG_FILE_MAX_SIZE | 10MB | 单个日志文件最大大小 |
| 日志文件保留天数 | LOG_FILE_MAX_HISTORY | 30 | 日志文件保留天数 |
| 日志文件总大小 | LOG_FILE_TOTAL_SIZE_CAP | 1GB | 日志文件总大小上限 |

### 7. MyBatis配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 日志实现 | MYBATIS_LOG_IMPL | StdOutImpl | MyBatis日志实现 |
| 语句超时时间 | MYBATIS_STATEMENT_TIMEOUT | 30 | SQL语句超时时间（秒） |
| 表前缀 | MYBATIS_TABLE_PREFIX | - | 数据库表前缀 |

### 8. Actuator监控配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 暴露端点 | ACTUATOR_ENDPOINTS | health,info,metrics,prometheus | 暴露的监控端点 |
| 基础路径 | ACTUATOR_BASE_PATH | /actuator | Actuator基础路径 |
| 健康检查详情 | ACTUATOR_HEALTH_SHOW_DETAILS | when-authorized | 健康检查详情显示策略 |
| 磁盘空间阈值 | ACTUATOR_HEALTH_DISK_THRESHOLD | 10MB | 磁盘空间预警阈值 |
| Prometheus启用 | ACTUATOR_PROMETHEUS_ENABLED | true | 是否启用Prometheus |

### 9. 跨域配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 允许的源 | CORS_ALLOWED_ORIGINS | http://localhost:3000 | 允许的跨域源 |
| 允许的方法 | CORS_ALLOWED_METHODS | GET,POST,PUT,DELETE,OPTIONS | 允许的HTTP方法 |
| 允许的头 | CORS_ALLOWED_HEADERS | * | 允许的请求头 |
| 允许凭证 | CORS_ALLOW_CREDENTIALS | true | 是否允许凭证 |
| 最大缓存时间 | CORS_MAX_AGE | 3600 | 预检请求缓存时间（秒） |

### 10. 安全配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 忽略URL | SECURITY_IGNORE_URLS | /auth/login,/auth/register | 不需要认证的URL |
| 限流启用 | RATE_LIMIT_ENABLED | true | 是否启用限流 |
| 每分钟请求数 | RATE_LIMIT_REQUESTS_PER_MINUTE | 60 | 每分钟最大请求数 |

### 11. 文件上传配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最大文件大小 | UPLOAD_MAX_FILE_SIZE | 10MB | 最大文件大小 |
| 最大请求大小 | UPLOAD_MAX_REQUEST_SIZE | 10MB | 最大请求大小 |
| 文件大小阈值 | UPLOAD_FILE_SIZE_THRESHOLD | 2KB | 文件大小阈值 |

### 12. 文件存储配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 存储类型 | STORAGE_TYPE | local | 存储类型：local/oss |
| 本地存储路径 | STORAGE_LOCAL_PATH | ./uploads | 本地存储路径 |
| 最大文件大小 | STORAGE_MAX_SIZE | 10MB | 最大文件大小 |
| 允许的文件类型 | STORAGE_ALLOWED_TYPES | jpg,jpeg,png,gif,pdf... | 允许的文件类型 |

### 13. 异步任务配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 核心线程数 | ASYNC_POOL_CORE_SIZE | 5 | 核心线程数 |
| 最大线程数 | ASYNC_POOL_MAX_SIZE | 20 | 最大线程数 |
| 队列容量 | ASYNC_POOL_QUEUE_CAPACITY | 100 | 队列容量 |
| 空闲线程存活时间 | ASYNC_POOL_KEEP_ALIVE | 60 | 空闲线程存活时间（秒） |

### 14. 定时任务配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 线程池大小 | SCHEDULING_POOL_SIZE | 5 | 定时任务线程池大小 |

### 15. 缓存配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 缓存类型 | CACHE_TYPE | redis | 缓存类型 |
| 缓存过期时间 | CACHE_TTL | 3600000 | 缓存过期时间（毫秒） |

### 16. 业务配置

#### 预约配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最大提前预约天数 | RESERVATION_MAX_DAYS | 30 | 最大提前预约天数 |
| 最小提前预约小时数 | RESERVATION_MIN_HOURS | 2 | 最小提前预约小时数 |
| 每天最大预约小时数 | RESERVATION_MAX_HOURS | 8 | 每天最大预约小时数 |
| 取消预约提前小时数 | RESERVATION_CANCEL_HOURS | 24 | 取消预约提前小时数 |

#### 设备配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最大借用天数 | DEVICE_MAX_BORROW_DAYS | 30 | 设备最大借用天数 |
| 逾期罚款（每天） | DEVICE_OVERDUE_FINE | 10.0 | 逾期罚款金额（元/天） |

#### 耗材配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 预警阈值 | CONSUMABLE_WARNING_THRESHOLD | 10 | 库存预警阈值 |
| 自动预警启用 | CONSUMABLE_AUTO_WARNING | true | 是否启用自动预警 |

### 17. 通知配置

#### 邮件通知

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 邮件启用 | NOTIFICATION_EMAIL_ENABLED | false | 是否启用邮件通知 |
| SMTP主机 | NOTIFICATION_EMAIL_HOST | smtp.example.com | SMTP服务器地址 |
| SMTP端口 | NOTIFICATION_EMAIL_PORT | 587 | SMTP服务器端口 |
| SMTP用户名 | NOTIFICATION_EMAIL_USERNAME | - | SMTP用户名 |
| SMTP密码 | NOTIFICATION_EMAIL_PASSWORD | - | SMTP密码 |
| 发件人 | NOTIFICATION_EMAIL_FROM | noreply@example.com | 发件人邮箱 |

#### 短信通知

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 短信启用 | NOTIFICATION_SMS_ENABLED | false | 是否启用短信通知 |
| 服务提供商 | NOTIFICATION_SMS_PROVIDER | aliyun | 短信服务提供商 |
| 访问密钥 | NOTIFICATION_SMS_ACCESS_KEY | - | 访问密钥 |
| 私密密钥 | NOTIFICATION_SMS_SECRET_KEY | - | 私密密钥 |

## 🎨 前端配置

### 1. 应用配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 应用标题 | VITE_APP_TITLE | 实验室管理系统 | 应用标题 |
| 运行环境 | VITE_APP_ENV | development | 运行环境 |

### 2. API配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| API基础路径 | VITE_API_BASE_URL | /api | API基础路径 |
| API超时时间 | VITE_API_TIMEOUT | 10000 | API请求超时时间（毫秒） |

### 3. 上传配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 最大文件大小 | VITE_UPLOAD_MAX_SIZE | 10485760 | 最大文件大小（字节） |
| 允许的文件类型 | VITE_UPLOAD_ALLOWED_TYPES | jpg,jpeg,png,gif... | 允许的文件类型 |

### 4. 功能开关

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 启用Mock | VITE_ENABLE_MOCK | false | 是否启用Mock数据 |
| 启用调试 | VITE_ENABLE_DEBUG | true | 是否启用调试模式 |
| 启用控制台日志 | VITE_ENABLE_CONSOLE_LOG | true | 是否启用控制台日志 |

### 5. Token配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| Token键名 | VITE_TOKEN_KEY | lab_token | Token存储键名 |
| Token前缀 | VITE_TOKEN_PREFIX | Bearer | Token前缀 |

### 6. 语言配置

| 参数名 | 环境变量 | 默认值 | 说明 |
|--------|---------|--------|------|
| 默认语言 | VITE_DEFAULT_LANGUAGE | zh-CN | 默认语言 |

## 📝 使用说明

### 1. 环境变量配置

```bash
# 复制环境变量模板
cp .env.template .env

# 编辑配置文件
vim .env
```

### 2. Docker部署配置

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=lab_management
      - DB_USERNAME=labuser
      - DB_PASSWORD=${DB_PASSWORD}
```

### 3. Kubernetes配置

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: lab-management-config
data:
  SPRING_PROFILES_ACTIVE: "prod"
  DB_HOST: "mysql-service"
  DB_PORT: "3306"
  DB_NAME: "lab_management"
```

### 4. 配置优先级

配置加载优先级从高到低：

1. 命令行参数
2. 环境变量
3. application-{profile}.yml
4. application.yml

## ⚠️ 注意事项

1. **生产环境必须修改默认密码**
2. **JWT密钥必须使用强密码**
3. **数据库连接池大小需要根据实际负载调整**
4. **日志级别生产环境建议设置为info或warn**
5. **跨域配置需要根据实际域名配置**

---

**最后更新**: 2026-04-14
