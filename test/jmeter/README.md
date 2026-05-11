# JMeter 性能测试使用说明

## 前置条件
1. 安装 JMeter 5.5+: https://jmeter.apache.org/
2. 确保后端服务可访问（默认目标: `maco.hackercd.cn:10082`）
3. `test-users.csv` 与 `.jmx` 脚本在同一目录

## 测试脚本说明

| 脚本 | 说明 |
|------|------|
| `实验室管理系统综合性能测试.jmx` | **主测试脚本**，7个线程组 + setUp，550多用户CSV数据驱动 |
| `test-users.csv` | 测试用户数据（500学生 + 50教师，含表头） |
| `实验室管理系统并发测试.jmx` | 旧版并发测试脚本（token认证已修复） |
| `实验室管理系统性能测试.jmx` | 旧版性能测试脚本（token认证已修复） |
| `HTTP请求.jmx` | 单接口调试用 |

## 准备工作（首次运行）

JMeter 脚本的 setUp 线程组会自动从 CSV 读取 550 个用户并通过管理员 API 批量创建。管理员凭据在测试计划的全局变量中配置。

### CSV 数据文件 — `test-users.csv`

```csv
username,password,realName,role
ptuser001,Test123456,压测用户001,STUDENT
ptuser002,Test123456,压测用户002,STUDENT
...（共500个学生用户）
tteacher001,Test123456,测试教师001,TEACHER
...（共50个教师用户）
```

- 编码：UTF-8
- 分隔符：逗号
- 第一行为表头（JMeter 自动跳过）

## 运行测试

```bash
cd test/jmeter

# GUI 模式（编辑/调试）
jmeter -t 实验室管理系统综合性能测试.jmx

# 命令行模式（正式压测，生成HTML报告）
jmeter -n -t 实验室管理系统综合性能测试.jmx -l result.jtl -e -o report/
```

## 测试场景（综合性能测试脚本）

| 线程组 | 线程 | 预热 | 持续 | 数据源 | 说明 |
|--------|------|------|------|--------|------|
| **A-数据准备(setUp)** | 1 | 1s | 1次 | CSV+Admin | 管理员登录 → 获取测试ID → 循环550次创建测试用户 |
| **B-混合业务负载** | 500 | 30s | 600s | CSV | 每线程一个独立用户：登录→仪表盘→实验室→设备→预约→公告 |
| **C-预约并发竞态** | 260 | 2s | 1次 | CSV | 260用户同时创建重叠时间段预约（测试冲突检测） |
| **D-设备借用并发** | 260 | 2s | 1次 | CSV | 260用户并发借用同一设备（测试 FOR UPDATE 悲观锁） |
| **E-审批并发** | 50 | 2s | 1次 | Admin | 50线程管理员并发审批预约（测试 FOR UPDATE 悲观锁） |
| **F-峰值读取** | 500 | 10s | 1次 | CSV | 500用户突发查询：仪表盘+预约概览+设备列表 |
| **G-综合业务流程** | 500 | 30s | 600s | CSV | 完整操作链：登录→仪表盘→实验室→预约→耗材→公告 |

### CSV 数据分发策略

| 配置项 | 设置 | 说明 |
|--------|------|------|
| Sharing mode | `All threads` | 线程组内所有线程共享一个读指针，确保每个用户凭据唯一 |
| Recycle on EOF | `false` | 数据耗尽后不循环复用 |
| Stop thread on EOF | `false` | 数据耗尽后不停止线程（空值会被 JMeter 忽略） |

- B组 500 线程 → 消耗 CSV 第 1-500 行（学生用户）
- C组 260 线程 → 消耗 CSV 第 1-260 行
- D组 260 线程 → 消耗 CSV 第 1-260 行
- F组 500 线程 → 消耗 CSV 第 1-500 行
- G组 500 线程 → 消耗 CSV 第 1-500 行
- E组（审批）→ 使用 Admin 凭据，不消耗 CSV 行

> 每个线程组有独立的 CSV Data Set Config 实例，各从第1行开始读取。550 行数据足够覆盖最大 500 线程的场景。

## 覆盖的 API 端点

### 认证模块
- `POST /api/auth/login` - 用户登录（所有线程组）
- `POST /api/user` - 创建测试用户（setUp 组，管理员批量创建）

### 读操作
- `GET /api/statistics/dashboard` - 仪表盘多表聚合统计
- `GET /api/lab/list` - 实验室全量列表
- `GET /api/lab/page` - 实验室分页查询
- `GET /api/device/page` - 设备分页查询
- `GET /api/reservation/my` - 我的预约分页
- `GET /api/reservation/list` - 管理端预约列表（含 PENDING 过滤）
- `GET /api/reservation/overview` - 预约当日概览
- `GET /api/consumable/list` - 耗材列表
- `GET /api/announcement/list` - 公告列表（公开，无需认证）

### 写操作
- `POST /api/reservation` - 创建预约（含冲突检测）
- `POST /api/device/{id}/borrow` - 借用设备（FOR UPDATE 悲观锁）
- `PUT /api/reservation/{id}/approve` - 审批预约（FOR UPDATE 悲观锁）

## 多用户模拟机制

```
test-users.csv (550行)
    ↓
setUp (A-数据准备)
  ├── A01: 管理员登录 → 提取 admin token
  ├── A02-A05: 获取 labId/deviceId/consumableId → props 共享
  └── A06: 循环 550 次
       ├── CSV 读取一行 (username, password, realName, role)
       └── POST /api/user (管理员创建用户)
    ↓
业务线程组 (B/C/D/F/G)
  ├── CSV Data Set Config (Sharing: All threads)
  │    每个线程获取独立的用户凭据
  ├── Once Only / Login: POST /api/auth/login
  │    Body: {"username":"${username}","password":"${password}"}
  ├── JSON Extractor: $.data.token → myToken
  └── 后续业务请求: Authorization: Bearer ${myToken}
```

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

如需调整 CSV 数据，编辑 `test-users.csv` 并同步修改 setUp 循环次数。
