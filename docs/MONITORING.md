# 监控系统文档

## 架构

```
后端 /actuator/prometheus ──→ Prometheus (采集) ──→ Grafana (面板)
Docker 容器指标 ──→ cAdvisor ──→ Prometheus
系统指标 ──→ node-exporter ──→ Prometheus
MySQL 指标 ──→ mysql-exporter ──→ Prometheus
Redis 指标 ──→ redis-exporter ──→ Prometheus
告警 ──→ Alertmanager ──→ 邮件/微信/Webhook
```

## 部署方式

### 方式一：Jenkins 部署时一并启动（推荐生产环境）

Jenkins 构建时勾选 **`DEPLOY_MONITOR`**，和业务容器一起部署。

### 方式二：手动启动

```bash
cd monitor
docker-compose -f docker-compose.monitoring.yml up -d
```

### 停止

```bash
cd monitor
docker-compose -f docker-compose.monitoring.yml down
```

## 访问地址

| 服务 | 端口 | 地址 | 默认账号 |
|------|------|------|---------|
| **Grafana** | 3001 | `http://主机IP:3001` | admin / admin123 |
| **Prometheus** | 9090 | `http://主机IP:9090` | 无需认证 |
| **Alertmanager** | 9093 | `http://主机IP:9093` | 无需认证 |
| **cAdvisor** | 8080 | `http://主机IP:8080` | 无需认证 |

## Grafana 预置面板

| 面板 | UID | 内容 |
|------|-----|------|
| **服务概览** | `lab-management-overview` | 请求量(QPS)、P95 响应时间、JVM 堆内存、GC 暂停时间、HTTP 错误率 |
| **系统监控** | `system-monitoring` | CPU 使用率、内存/磁盘详情、网络流量、系统负载 |
| **日志分析** | `log-search-analysis` | 错误日志、服务日志分布、按关键词搜索（需 Loki） |

## Prometheus 采集配置

配置文件：`monitor/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s      # 采集间隔，可改为 5s（更细）或 30s（省存储）
  evaluation_interval: 15s   # 告警评估间隔

scrape_configs:
  - job_name: lab-management-backend
    metrics_path: /api/actuator/prometheus
    static_configs:
      - targets: ['backend:8081', 'host.docker.internal:8081']
```

### 采集指标

| 类型 | 指标 | 说明 |
|------|------|------|
| **JVM** | `jvm_memory_used_bytes` / `jvm_memory_max_bytes` | 堆内存使用/最大值 |
| | `jvm_gc_pause_seconds` | GC 暂停时间 |
| | `jvm_threads_live_threads` | 活跃线程数 |
| **HTTP** | `http_server_requests_seconds_count` | 请求次数 |
| | `http_server_requests_seconds_max` | 最大响应时间 |
| **系统** | `node_cpu_seconds_total` | CPU 使用率 |
| | `node_memory_MemAvailable_bytes` | 可用内存 |
| | `node_filesystem_avail_bytes` | 磁盘可用空间 |
| **数据库** | `mysql_global_status_threads_connected` | MySQL 连接数 |
| | `mysql_global_status_slow_queries` | 慢查询数 |
| **Redis** | `redis_connected_clients` | 连接数 |
| | `redis_memory_used_bytes` | 内存使用 |

## 告警规则

17 条告警规则，分 6 组（配置文件：`monitor/prometheus/alert_rules.yml`）：

| 分组 | 规则 | 严重级别 |
|------|------|---------|
| **服务** | 服务宕机 (>1min) | critical |
| | 接口延迟 >2s | warning |
| **JVM** | 堆内存 >80% | warning |
| | 堆内存 >90% | critical |
| | GC 暂停 >1s | warning |
| | 线程数 >200 | warning |
| **系统** | CPU >80% | warning |
| | 内存 >85% | warning |
| | 磁盘 <20% | warning |
| | 磁盘 <10% | critical |
| **数据库** | MySQL 宕机 | critical |
| | 连接数 >80% | warning |
| | 慢查询 >10/5min | warning |
| **Redis** | Redis 宕机 | critical |
| | 内存 >80% | warning |
| **HTTP** | 错误率 >5% (5min) | critical |
| | QPS >1000 | warning |

### 告警通知

配置文件：`monitor/alertmanager/alertmanager.yml`

默认使用占位符，需要替换为真实配置：
- **邮件**：修改 `smtp_smarthost`、`auth_username`、`auth_password`
- **微信**：修改 `corp_id`、`api_secret`、`agent_id`
- **Webhook**：修改 `url` 为目标地址

## 配置修改

1. 编辑 `monitor/prometheus/prometheus.yml` 改采集间隔
2. 编辑 `monitor/prometheus/alert_rules.yml` 改告警阈值
3. 编辑 `monitor/alertmanager/alertmanager.yml` 改通知渠道
4. 重启监控：`cd monitor && docker-compose -f docker-compose.monitoring.yml restart`
