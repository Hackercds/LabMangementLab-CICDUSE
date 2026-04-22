# 通用监控系统

一个开箱即用的监控系统解决方案，支持快速部署到任何项目。

## 🚀 快速开始

### Linux/macOS
```bash
# 一键初始化并启动
./setup.sh init && ./setup.sh start
```

### Windows
```cmd
# 一键初始化并启动
setup.bat init && setup.bat start
```

## 📦 包含组件

| 组件 | 端口 | 说明 |
|------|------|------|
| Prometheus | 9090 | 指标采集和存储 |
| Grafana | 3001 | 可视化面板 |
| Loki | 3100 | 日志聚合 |
| Alertmanager | 9093 | 告警管理 |
| cAdvisor | 8080 | 容器监控 |
| Blackbox Exporter | 9115 | 黑盒探测 |

## 📋 命令说明

```bash
# 初始化监控系统（首次使用）
./setup.sh init

# 启动监控系统
./setup.sh start

# 停止监控系统
./setup.sh stop

# 重启监控系统
./setup.sh restart

# 查看状态
./setup.sh status

# 查看日志
./setup.sh logs [服务名]

# 配置向导
./setup.sh config
```

## ⚙️ 配置说明

配置文件位于 `monitoring/config/project.conf`：

```bash
# 项目名称
PROJECT_NAME=my-project

# 后端服务地址
BACKEND_HOST=host.docker.internal
BACKEND_PORT=8080

# 前端服务地址
FRONTEND_HOST=host.docker.internal
FRONTEND_PORT=3000

# Grafana配置
GRAFANA_PORT=3001
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin123
```

## 🔧 集成到新项目

### 方法一：复制整个目录
```bash
# 复制到你的项目
cp -r monitoring-system /path/to/your-project/

# 进入目录
cd /path/to/your-project/monitoring-system

# 初始化并启动
./setup.sh init && ./setup.sh start
```

### 方法二：修改配置
```bash
# 编辑配置文件
vim monitoring/config/project.conf

# 修改后端地址和端口
BACKEND_HOST=your-backend-host
BACKEND_PORT=your-backend-port

# 重启生效
./setup.sh restart
```

## 📊 预置Dashboard

系统启动后，在Grafana中可导入以下Dashboard：

1. **JVM监控** - ID: 4701
2. **Spring Boot监控** - ID: 12900
3. **Node Exporter** - ID: 1860
4. **Docker监控** - ID: 11600
5. **Nginx监控** - ID: 12708

### 导入方法
1. 打开 Grafana → Dashboards → Import
2. 输入Dashboard ID
3. 选择Prometheus数据源
4. 点击Import

## 📝 日志采集配置

### 应用日志
将应用日志输出到 `monitoring/logs/` 目录：

```bash
# Java logback配置
<property name="LOG_PATH" value="./monitoring/logs"/>
<appender name="FILE" class="ch.qos.logback.core.FileAppender">
    <file>${LOG_PATH}/application.log</file>
</appender>
```

### Docker容器日志
自动采集Docker容器日志，无需额外配置。

## 🚨 告警配置

### 添加告警规则
编辑 `monitoring/prometheus/alert_rules.yml`：

```yaml
groups:
  - name: my_alerts
    rules:
      - alert: HighCPU
        expr: 100 - avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU使用率过高"
```

### 配置告警通知
编辑 `monitoring/alertmanager/alertmanager.yml`：

```yaml
receivers:
  - name: 'email-receiver'
    email_configs:
      - to: 'admin@example.com'
        from: 'alert@example.com'
        smarthost: 'smtp.example.com:587'
```

## 🔄 数据持久化

数据存储在 `monitoring/data/` 目录：
- `prometheus/` - Prometheus数据
- `grafana/` - Grafana配置和Dashboard
- `loki/` - 日志数据

## 🐛 常见问题

### 1. 端口冲突
修改 `config/project.conf` 中的端口配置。

### 2. Docker未启动
确保Docker Desktop已启动并运行。

### 3. 无法访问服务
检查防火墙设置，确保端口已开放。

### 4. 数据丢失
确保 `monitoring/data/` 目录有写入权限。

## 📚 进阶配置

### 添加自定义监控目标
编辑 `monitoring/prometheus/prometheus.yml`：

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:8080']
```

### 添加自定义Dashboard
将Dashboard JSON文件放入：
```
monitoring/grafana/provisioning/dashboards/
```

## 📄 许可证

MIT License
