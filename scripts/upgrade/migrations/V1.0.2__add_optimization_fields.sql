-- =====================================================
-- V1.0.2: 添加性能优化字段和索引
-- 优化预约冲突检测性能
-- 执行时间: 升级时
-- =====================================================

-- 1. 为reservation表添加复合索引，优化冲突检测查询
ALTER TABLE `reservation`
ADD INDEX `idx_lab_date_time_status` (`lab_id`, `reservation_date`, `start_time`, `end_time`, `status`);

-- 2. 为device_borrow_history表添加索引
ALTER TABLE `device_borrow_history`
ADD INDEX `idx_device_id` (`device_id`),
ADD INDEX `idx_borrower_id` (`borrower_id`),
ADD INDEX `idx_status` (`status`);

-- 3. 验证表结构
SELECT 'reservation表索引:' AS info;
SHOW INDEX FROM `reservation`;

SELECT 'device_borrow_history表索引:' AS info;
SHOW INDEX FROM `device_borrow_history`;
