-- 修复管理员密码
-- 密码是 admin123，BCrypt 哈希正确转义

UPDATE `user`
SET `password` = '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EHsM8'
WHERE `username` = 'admin';
