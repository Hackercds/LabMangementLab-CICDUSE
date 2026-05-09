# JMeter 并发测试使用说明

## 前置条件
1. 安装 JMeter 5.5+: https://jmeter.apache.org/
2. 确保后端运行在 http://localhost:8081

## 运行测试
```bash
# GUI 模式（编辑/调试）
jmeter -t 实验室管理系统并发测试.jmx

# 命令行模式（正式压测）
jmeter -n -t 实验室管理系统并发测试.jmx -l result.jtl -e -o report/
```

## 测试场景
| 场景 | 线程 | 说明 |
|------|------|------|
| 登录压测 | 50并发 | 模拟峰值登录 |
| 预约冲突 | 30并发 | 同一实验室+时间，验证冲突检测 |
| 查询压测 | 20并发 | 设备列表查询 |

## JWT 鉴权说明
系统使用 `Authorization: Bearer <token>` 鉴权。
JMeter 中通过"JSON提取器"从登录响应提取 token，
后续请求通过"HTTP Header Manager"携带。
