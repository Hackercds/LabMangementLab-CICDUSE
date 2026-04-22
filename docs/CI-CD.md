# CI/CD集成文档

## 📋 概述

本项目支持完整的CI/CD自动化部署流程，支持Jenkins、GitLab CI、GitHub Actions等多种CI/CD平台。

## 🚀 CI/CD流程

### 完整流程图

```
代码提交 → 代码检出 → 环境准备 → 构建 → 测试 → 代码质量检查 → Docker镜像构建 → 部署 → 冒烟测试
```

### 各阶段说明

1. **代码检出**: 从Git仓库检出最新代码
2. **环境准备**: 检查并准备构建环境（Java、Node.js、Python）
3. **构建**: 
   - 后端：Maven构建JAR包
   - 前端：npm构建生产版本
4. **测试**:
   - 后端单元测试
   - 前端单元测试
   - API自动化测试
5. **代码质量检查**: 
   - 后端：Checkstyle、SpotBugs
   - 前端：ESLint
6. **Docker镜像构建**: 构建并推送Docker镜像
7. **部署**: 
   - 测试环境：自动部署
   - 生产环境：手动审批后部署
8. **冒烟测试**: 部署后自动运行冒烟测试

## 🔧 支持的CI/CD平台

### 1. Jenkins

#### 配置步骤

1. **安装必要插件**
   - Pipeline
   - Docker Pipeline
   - Allure Plugin
   - Email Extension Plugin

2. **创建Pipeline项目**
   - 新建Pipeline项目
   - 选择"Pipeline script from SCM"
   - 配置Git仓库地址
   - 指定Jenkinsfile路径

3. **配置凭据**
   - Docker Registry凭据
   - SSH私钥
   - 数据库密码

4. **运行Pipeline**
   ```bash
   # 手动触发
   点击"Build Now"
   
   # 自动触发（配置Webhook）
   Git提交后自动触发
   ```

#### Pipeline阶段

```
代码检出 → 环境准备 → 后端构建 → 前端构建 → 后端单元测试 → 代码质量检查 
→ Docker镜像构建 → Docker镜像推送 → 部署到测试环境 → 部署到生产环境 
→ 冒烟测试 → API自动化测试
```

### 2. GitLab CI

#### 配置步骤

1. **配置GitLab Runner**
   ```bash
   # 安装GitLab Runner
   curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
   sudo apt-get install gitlab-runner
   
   # 注册Runner
   sudo gitlab-runner register
   ```

2. **配置环境变量**
   - Settings → CI/CD → Variables
   - 添加必要的凭据和配置

3. **自动触发**
   - 推送代码到develop分支：自动部署到测试环境
   - 推送代码到main分支：自动部署到生产环境

#### Pipeline阶段

```
build → test → quality → docker → deploy → smoke-test
```

### 3. GitHub Actions

#### 配置步骤

1. **配置Secrets**
   - Settings → Secrets and variables → Actions
   - 添加必要的凭据和配置

2. **自动触发**
   - 推送代码：自动触发CI/CD
   - Pull Request：运行构建和测试

#### Workflow阶段

```
backend-build → frontend-build → backend-test → frontend-test → code-quality 
→ docker-build → deploy-staging → deploy-production → smoke-test → api-test
```

## 🐳 Docker部署

### 开发环境

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 生产环境

```bash
# 设置环境变量
export MYSQL_ROOT_PASSWORD=your_root_password
export MYSQL_USER=labuser
export MYSQL_PASSWORD=your_password
export REDIS_PASSWORD=your_redis_password
export DOCKER_REGISTRY=registry.example.com
export IMAGE_TAG=latest

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 扩容后端服务
docker-compose -f docker-compose.prod.yml up -d --scale backend=3
```

## 🚀 部署策略

### 蓝绿部署

生产环境使用蓝绿部署策略，实现零停机部署：

1. **检测当前环境**: 判断当前运行的是蓝色还是绿色环境
2. **启动新环境**: 在新环境中启动最新版本
3. **健康检查**: 确保新环境健康
4. **切换流量**: 更新Nginx配置，切换流量到新环境
5. **停止旧环境**: 停止并删除旧环境容器

### 回滚策略

如果部署失败或冒烟测试失败：

1. **自动回滚**: Jenkins Pipeline自动回滚到上一个版本
2. **手动回滚**: 
   ```bash
   # 恢复备份
   cd /opt/lab-management/backups
   tar -xzf backup_YYYYMMDD_HHMMSS.tar.gz
   
   # 恢复数据库
   docker exec -i lab-mysql-prod mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} lab_management < backup_YYYYMMDD_HHMMSS/database.sql
   
   # 恢复镜像
   docker load -i backup_YYYYMMDD_HHMMSS/backend.tar
   docker load -i backup_YYYYMMDD_HHMMSS/frontend.tar
   
   # 重启服务
   docker-compose -f docker-compose.prod.yml down
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 🧪 自动化测试集成

### 冒烟测试

部署完成后自动运行冒烟测试：

```bash
# 运行冒烟测试
cd tests
python run_tests.py smoke

# 查看测试报告
allure open reports/allure-report
```

### API自动化测试

在测试环境自动运行完整的API自动化测试：

```bash
# 运行完整测试套件
cd tests
python run_tests.py full

# 查看测试报告
allure open reports/allure-report
```

## 📊 监控和告警

### 健康检查

所有服务都配置了健康检查：

- **MySQL**: `mysqladmin ping`
- **Redis**: `redis-cli ping`
- **后端**: `/api/actuator/health`
- **前端**: HTTP GET `/`

### 日志收集

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql
```

### 告警通知

- **邮件通知**: 构建成功/失败时发送邮件
- **Slack通知**: 集成Slack Webhook
- **企业微信通知**: 集成企业微信机器人

## 🔐 安全配置

### 凭据管理

- **Jenkins**: 使用Jenkins Credentials管理
- **GitLab CI**: 使用CI/CD Variables
- **GitHub Actions**: 使用Secrets

### 配置管理

项目支持多环境配置，通过环境变量管理不同环境的配置参数：

#### 开发环境配置

```bash
# .env.development
SPRING_PROFILES_ACTIVE=dev
DB_HOST=localhost
DB_PORT=3306
LOG_LEVEL_APP=debug
```

#### 测试环境配置

```bash
# .env.test
SPRING_PROFILES_ACTIVE=test
DB_HOST=test-db.example.com
DB_PORT=3306
LOG_LEVEL_APP=info
```

#### 生产环境配置

```bash
# .env.production
SPRING_PROFILES_ACTIVE=prod
DB_HOST=prod-db.example.com
DB_PORT=3306
LOG_LEVEL_APP=warn
```

#### 配置参数说明

所有配置参数的详细说明请参考 [配置参数说明文档](CONFIGURATION.md)

### 网络安全

- 所有服务运行在Docker内部网络
- 只有必要的端口暴露到外部
- 使用Nginx作为反向代理

### 数据库安全

- 使用强密码
- 限制远程访问
- 定期备份

## 📝 最佳实践

1. **代码提交前**: 运行本地测试
2. **Pull Request**: 自动运行CI
3. **合并到develop**: 自动部署到测试环境
4. **合并到main**: 手动审批后部署到生产环境
5. **部署后**: 自动运行冒烟测试
6. **定期备份**: 每天自动备份数据库

## 🆘 故障排查

### 常见问题

1. **构建失败**
   ```bash
   # 检查日志
   docker-compose logs backend
   
   # 检查依赖
   cd backend
   mvn dependency:tree
   ```

2. **部署失败**
   ```bash
   # 检查服务状态
   docker-compose ps
   
   # 检查健康状态
   curl -f http://localhost:8081/api/actuator/health
   ```

3. **测试失败**
   ```bash
   # 查看测试报告
   allure open reports/allure-report
   
   # 运行失败测试
   pytest --lf
   ```

## 📞 联系方式

如有问题，请联系DevOps团队。

---

**最后更新**: 2026-04-14
