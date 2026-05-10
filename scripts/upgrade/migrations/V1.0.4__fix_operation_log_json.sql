-- V1.0.4: 修复 operation_log 表 JSON 列改为 TEXT
-- JSON 列不接受 null/非JSON字符串导致插入失败
ALTER TABLE `operation_log` MODIFY COLUMN `before_snapshot` TEXT COMMENT '操作前数据快照';
ALTER TABLE `operation_log` MODIFY COLUMN `after_snapshot` TEXT COMMENT '操作后数据快照';
