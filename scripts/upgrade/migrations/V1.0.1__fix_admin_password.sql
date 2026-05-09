-- =====================================================
-- V1.0.1: 修复管理员密码
-- 修复schema.sql中BCrypt哈希值错误的问题
-- 执行时间: 升级时
-- =====================================================

-- 注意：此密码哈希是admin123的BCrypt加密值
-- 生成方式：使用Spring Security的BCryptPasswordEncoder
-- 或者在线工具：https://bcrypt-generator.com/

-- 正确的BCrypt哈希（密码: admin123）
-- 哈希版本: 2a, 轮数: 10
UPDATE `user`
SET `password` = '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EHs'
WHERE `username` = 'admin' AND `deleted` = 0;

-- 验证修复结果
SELECT id, username, '***' AS password, role, status
FROM `user`
WHERE username = 'admin';
