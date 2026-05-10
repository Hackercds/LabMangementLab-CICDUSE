# CHANGELOG

## [1.1.0] - 2026-05-10

### Changed
- **数据库结构调整**：device 表移除借用相关字段，设备只保留当前状态
- DeviceService 借用/归还逻辑重构，借用记录独立存储到 device_borrow_history 表
- Jenkinsfile 全面改造：参数化构建、凭据管理、移除硬编码IP和密码
- docker-compose.yml 使用环境变量替换硬编码密码
- **配置文件合一**：4个application*.yml合并为1个(application.yml)，config/config.yaml 作为唯一配置入口
- **目录重组**：monitoring→monitor，scripts精简为7个，config/目录为配置中心
- 监控网络与业务网络统一为 lab-network

### Added
- 新增 device_borrow_history 表（设备借用历史）
- 新增 DeviceBorrowHistory 实体及 Mapper
- operation_log 表新增 before_snapshot、after_snapshot JSON 列
- 新增数据库迁移脚本 V1.0.1、V1.0.2、V1.0.3
- CHANGELOG.md
- **小白指南** (docs/小白指南.md) — Docker/裸机双模式零基础教程
- **裸机部署** (scripts/raw_start.ps1/.bat) — winget 自动安装 Java/Node/MySQL
- **管理员功能** — 撤销任意预约、代他人申请、Excel批量导入、日历概览
- **预约通知** — 审批/撤销/强制审批自动公告通知用户，顶部铃铛弹窗
- **时间校验** — 禁止预约过去时间，客户端时间偏差超5分钟警告
- **管理员时间覆盖** — 可设置模拟日期用于测试
- **每周重复预约** — repeatWeeks参数，自动跳过冲突周
- **Excel模板下载** — GET /batch-template，含表头和示例行

### Fixed
- **并发竞态条件修复**：DeviceService borrow/return、ConsumableService in/out 添加 SELECT FOR UPDATE 悲观锁
- **审批冲突检测加锁**：ReservationService approve 使用 countAllConflictsForUpdate
- **JWT 密钥一致性**：application.yml 默认段改用 ${JWT_SECRET} 占位符
- **JwtUtils.getSigningKey()**：移除无意义的 Base64.encode() 双层编码
- **操作日志IP**：nginx X-Real-IP/X-Forwarded-For 真实客户端IP获取
- **前端端口10080**：Chrome ERR_UNSAFE_PORT，改用18080

### Security
- Jenkinsfile 密码改用 credentials()，不硬编码
- .env.example 移除所有真实密码，替换为占位符
- CORS 默认值从 * 改为 http://localhost

### Changed (Frontend)
- Login.vue 添加 Element Plus 表单验证规则 + 密码可见性切换
- Reservation.vue 添加表单验证规则
- MyReservation.vue/DeviceList.vue 添加空状态显示
- 登录页失败时 el-alert 内联错误提示
- 管理员/教师/学生顶部通知铃铛

### Removed
- data.sql 移除（初始数据已整合至 schema.sql）
- monitoring-system/ 重复目录
- scripts/ 中15个冗余脚本
- deploy.conf 重复配置
- **监控网络统一**：lab-monitoring → lab-network
- **目录大扫除**：删除 monitoring-system/、example/、10+多余脚本

### Added
- 新增 docs/小白指南.md（面向非技术人员）
- 新增 init-deploy.sh / init-deploy.bat（一键部署）
- 新增 device_borrow_history 表（设备借用历史）
- 新增 DeviceBorrowHistory 实体及 Mapper
- operation_log 表新增 before_snapshot、after_snapshot JSON 列
- 新增数据库迁移脚本 V1.0.1、V1.0.2、V1.0.3
- CHANGELOG.md

### Fixed
- **并发竞态条件修复**：DeviceService borrow/return、ConsumableService in/out 添加 SELECT FOR UPDATE 悲观锁
- **审批冲突检测加锁**：ReservationService approve 使用 countAllConflictsForUpdate 锁住冲突行
- **操作日志快照**：DeviceService、ConsumableService、ReservationService 关键操作填充 before/after 快照
- ReservationMapper 添加存储过程调用方法

### Security
- Jenkinsfile 密码改用 credentials()，不硬编码
- .env.example 移除所有真实密码，替换为占位符
- CORS 默认值从 * 改为 http://localhost

### Changed (Frontend)
- Login.vue 添加 Element Plus 表单验证规则 + 密码可见性切换
- Reservation.vue 添加表单验证规则
- MyReservation.vue、DeviceList.vue 添加空状态显示

### Removed
- data.sql 移除（初始数据已整合至 schema.sql）

---

## [1.0.0] - 2026-04

### Added
- 实验室管理系统初始版本
- 用户管理、实验室管理、设备管理、预约管理、耗材管理
- JWT 认证、RBAC 权限控制
- 预约冲突检测与审批系统
- CI/CD 集成（Jenkinsfile、GitLab CI、Docker Compose）
- 监控系统基础设施（Prometheus、Grafana、Loki、Alertmanager）
