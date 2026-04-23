-- 系统配置表
CREATE TABLE IF NOT EXISTS `system_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `config_key` VARCHAR(64) NOT NULL UNIQUE COMMENT '配置键',
  `config_value` VARCHAR(256) NOT NULL COMMENT '配置值',
  `description` VARCHAR(256) DEFAULT NULL COMMENT '描述',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 初始化配置
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('auto_approve_teacher', 'false', '教师审批预约时是否自动审批无冲突预约'),
('max_reservation_per_day', '3', '每个学生每天最多预约次数'),
('max_advance_days', '30', '最多可提前预约天数');
