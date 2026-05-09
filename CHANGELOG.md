# CHANGELOG

## [1.1.0] - 2026-05-10

### Changed
- **数据库结构调整**：device 表移除借用相关字段，设备只保留当前状态
- DeviceService 借用/归还逻辑重构，借用记录独立存储到 device_borrow_history 表
- Jenkinsfile 全面改造：参数化构建、凭据管理、移除硬编码IP和密码
- docker-compose.yml 使用环境变量替换硬编码密码
- **配置文件合一**：4个application*.yml合并为1个(application.yml)
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
