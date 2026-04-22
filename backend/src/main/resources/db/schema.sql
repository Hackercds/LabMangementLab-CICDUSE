-- 创建数据库
CREATE DATABASE IF NOT EXISTS lab_management DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE lab_management;

-- 1. 用户表
CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE COMMENT '学号/工号',
    `password` VARCHAR(255) NOT NULL COMMENT '加密密码',
    `real_name` VARCHAR(50) COMMENT '真实姓名',
    `role` ENUM('STUDENT','TEACHER','ADMIN') NOT NULL COMMENT '角色',
    `phone` VARCHAR(20) COMMENT '联系电话',
    `email` VARCHAR(100) COMMENT '邮箱',
    `status` ENUM('ENABLED','DISABLED') DEFAULT 'ENABLED' COMMENT '账号状态',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `last_login_time` DATETIME COMMENT '最后登录时间',
    `remark` VARCHAR(500) COMMENT '备注',
    `create_by` BIGINT COMMENT '创建人',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX idx_username(username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. 实验室表
CREATE TABLE IF NOT EXISTS `lab` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE COMMENT '实验室名称',
    `location` VARCHAR(100) COMMENT '位置',
    `capacity` INT COMMENT '容纳人数',
    `device_count` INT DEFAULT 0 COMMENT '设备数量',
    `status` ENUM('FREE','OCCUPIED','MAINTENANCE') DEFAULT 'FREE' COMMENT '当前状态',
    `director` VARCHAR(50) COMMENT '负责人',
    `phone` VARCHAR(20) COMMENT '联系电话',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    `remark` VARCHAR(500) COMMENT '备注',
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='实验室表';

-- 3. 设备表
CREATE TABLE IF NOT EXISTS `device` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL COMMENT '设备名称',
    `model` VARCHAR(100) COMMENT '型号',
    `serial_number` VARCHAR(100) COMMENT '序列号',
    `lab_id` BIGINT NOT NULL COMMENT '所属实验室ID',
    `purchase_date` DATE COMMENT '购买日期',
    `status` ENUM('NORMAL','BORROWED','MAINTENANCE','SCRAPPED') DEFAULT 'NORMAL' COMMENT '状态',
    `borrower_id` BIGINT COMMENT '借用人ID',
    `borrow_time` DATETIME COMMENT '借用时间',
    `expect_return_time` DATE COMMENT '预计归还时间',
    `return_time` DATETIME COMMENT '实际归还时间',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    `remark` VARCHAR(500) COMMENT '备注',
    INDEX idx_lab_id(lab_id),
    INDEX idx_status(status),
    INDEX idx_borrower_id(borrower_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备表';

-- 4. 预约记录表
CREATE TABLE IF NOT EXISTS `reservation` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL COMMENT '预约人ID',
    `lab_id` BIGINT NOT NULL COMMENT '实验室ID',
    `reservation_date` DATE NOT NULL COMMENT '预约日期',
    `start_time` TIME NOT NULL COMMENT '开始时间',
    `end_time` TIME NOT NULL COMMENT '结束时间',
    `purpose` VARCHAR(500) COMMENT '预约事由',
    `participant_count` INT COMMENT '参与人数',
    `status` ENUM('PENDING','APPROVED','REJECTED','CANCELED') DEFAULT 'PENDING' COMMENT '审批状态',
    `approver_id` BIGINT COMMENT '审批人ID',
    `approve_time` DATETIME COMMENT '审批时间',
    `approve_comment` VARCHAR(500) COMMENT '审批意见',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX idx_user_id(user_id),
    INDEX idx_lab_id(lab_id),
    INDEX idx_reservation_date(reservation_date),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预约记录表';

-- 5. 耗材表
CREATE TABLE IF NOT EXISTS `consumable` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL COMMENT '耗材名称',
    `specification` VARCHAR(100) COMMENT '规格',
    `unit` VARCHAR(20) COMMENT '单位',
    `current_stock` DECIMAL(10,2) DEFAULT 0 COMMENT '当前库存',
    `warning_threshold` DECIMAL(10,2) DEFAULT 0 COMMENT '预警阈值',
    `location` VARCHAR(100) COMMENT '存放位置',
    `director` VARCHAR(50) COMMENT '负责人',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    `remark` VARCHAR(500) COMMENT '备注'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='耗材表';

-- 6. 耗材出入库记录表
CREATE TABLE IF NOT EXISTS `consumable_log` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `consumable_id` BIGINT NOT NULL COMMENT '耗材ID',
    `operation_type` ENUM('IN','OUT') NOT NULL COMMENT '操作类型：入库/出库',
    `quantity` DECIMAL(10,2) NOT NULL COMMENT '数量',
    `operator_id` BIGINT NOT NULL COMMENT '操作人ID',
    `operation_time` DATETIME NOT NULL COMMENT '操作时间',
    `receiver` VARCHAR(50) COMMENT '领用人',
    `purpose` VARCHAR(500) COMMENT '用途',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX idx_consumable_id(consumable_id),
    INDEX idx_operation_time(operation_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='耗材出入库记录表';

-- 7. 公告表
CREATE TABLE IF NOT EXISTS `announcement` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL COMMENT '标题',
    `content` TEXT COMMENT '内容',
    `publisher_id` BIGINT NOT NULL COMMENT '发布人ID',
    `publish_time` DATETIME COMMENT '发布时间',
    `is_top` TINYINT DEFAULT 0 COMMENT '是否置顶：0-否，1-是',
    `status` ENUM('DRAFT','PUBLISHED','CLOSED') DEFAULT 'PUBLISHED' COMMENT '状态',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX idx_is_top(is_top),
    INDEX idx_status(status),
    INDEX idx_publish_time(publish_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告表';

-- 8. 操作日志表
CREATE TABLE IF NOT EXISTS `operation_log` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `operator_id` BIGINT COMMENT '操作人ID',
    `operation_time` DATETIME COMMENT '操作时间',
    `operation_type` VARCHAR(50) COMMENT '操作类型',
    `module` VARCHAR(50) COMMENT '操作模块',
    `description` VARCHAR(1000) COMMENT '内容描述',
    `ip_address` VARCHAR(50) COMMENT 'IP地址',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX idx_operator_id(operator_id),
    INDEX idx_operation_time(operation_time),
    INDEX idx_module(module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志表';

-- 初始化数据：预置管理员账号，密码是 admin123 (BCrypt加密)
INSERT IGNORE INTO `user` (username, password, real_name, role, status) VALUES
('admin', '$2b$10$CgNT9cdBi21.gNYtDwHiUeK3.0AGczNorbrEklIbeKC/rilrlmLqW', '系统管理员', 'ADMIN', 'ENABLED');

-- 预置几个实验室数据
INSERT IGNORE INTO `lab` (name, location, capacity, device_count, status) VALUES
('计算机实验室1号楼101', '1号楼101室', 50, 50, 'FREE'),
('电子工程实验室2号楼203', '2号楼203室', 30, 25, 'FREE'),
('创新实验室3号楼305', '3号楼305室', 20, 15, 'FREE');

-- 预置几个耗材数据
INSERT IGNORE INTO `consumable` (name, specification, unit, current_stock, warning_threshold, location) VALUES
('一次性手套', '中号', '包', 50, 10, '储物柜A1'),
('打印纸', 'A4', '箱', 20, 5, '储物柜A2'),
('U盘', '16GB', '个', 10, 3, '储物柜B1'),
('网线', 'RJ45', '根', 15, 5, '储物柜B2');
