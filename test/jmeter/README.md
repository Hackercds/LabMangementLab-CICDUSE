# JMeter 性能测试使用说明

## 前置条件
1. 安装 JMeter 5.5+: https://jmeter.apache.org/
2. 确保后端服务可访问（默认目标: `maco.hackercd.cn:10082`）

## 测试脚本说明

| 脚本 | 说明 |
|------|------|
| `实验室管理系统综合性能测试.jmx` | **主测试脚本**，6个线程组，覆盖全部业务场景 |
| `实验室管理系统并发测试.jmx` | 旧版并发测试脚本（已弃用） |
| `HTTP请求.jmx` | 单接口调试用 |

## 运行测试

```bash
# GUI 模式（编辑/调试）
jmeter -t 实验室管理系统综合性能测试.jmx

# 命令行模式（正式压测，生成HTML报告）
jmeter -n -t 实验室管理系统综合性能测试.jmx -l result.jtl -e -o report/
```

## 测试场景（综合性能测试脚本）

| 线程组 | 类型 | 线程数 | 预热 | 持续时间 | 说明 |
|--------|------|--------|------|----------|------|
| A-数据准备 | setUp | 1 | 1s | 1次 | 管理员登录、获取lab/device/consumable ID |
| B-混合业务负载 | 普通 | 30 | 5s | 60s | 持续读写混合：仪表盘→实验室→设备→预约→公告 |
| C-预约并发竞态 | 普通 | 50 | 2s | 1次 | 50并发同时创建重叠时间段预约（测试冲突检测） |
| D-设备借用并发 | 普通 | 50 | 2s | 1次 | 50并发借用同一设备（测试FOR UPDATE悲观锁） |
| E-峰值读取 | 普通 | 200 | 10s | 1次 | 200并发突发查询：仪表盘+预约概览+设备列表 |
| F-综合业务流程 | 普通 | 20 | 5s | 60s | 完整用户操作链：登录→仪表盘→实验室→预约→设备→耗材→公告 |

## 覆盖的 API 端点

### 认证模块
- `POST /api/auth/login` - 用户登录（所有线程组）

### 读操作
- `GET /api/statistics/dashboard` - 仪表盘多表聚合统计
- `GET /api/lab/list` - 实验室全量列表
- `GET /api/lab/page` - 实验室分页查询
- `GET /api/device/page` - 设备分页查询
- `GET /api/reservation/my` - 我的预约分页
- `GET /api/reservation/overview` - 预约当日概览
- `GET /api/consumable/list` - 耗材列表
- `GET /api/announcement/list` - 公告列表（公开，无需认证）

### 写操作（测试并发一致性）
- `POST /api/reservation` - 创建预约（含冲突检测）
- `POST /api/device/{id}/borrow` - 借用设备（FOR UPDATE悲观锁）

## JWT 鉴权机制

API 响应格式：
```json
{"code": 200, "message": "success", "data": {"token": "eyJ...", "userId": 1, ...}}
```

JMeter 实现方式：
1. 每个线程先请求 `POST /api/auth/login` 获取 token
2. 通过 `JSON提取器` 从 `$.data.token` 提取 JWT
3. 后续请求通过 `HTTP Header Manager` 携带 `Authorization: Bearer ${token}`
4. setUp 线程组将关键ID通过 `props` 共享给其他线程组

## 配置修改

如需修改目标服务器，编辑测试计划的 **全局变量**：
- `BASEURL` - 目标域名/IP（默认: `maco.hackercd.cn`）
- `PORT` - 目标端口（默认: `10082`）
- `ADMIN_USER` - 管理员账号（默认: `admin`）
- `ADMIN_PASS` - 管理员密码（默认: `admin123`）
