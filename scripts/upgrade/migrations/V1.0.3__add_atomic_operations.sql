-- =====================================================
-- V1.0.3: 添加原子操作存储过程
-- 用于解决并发场景下的数据竞争问题
-- 执行时间: 升级时
-- =====================================================

-- 1. 创建设备借用原子操作存储过程
DELIMITER //
CREATE PROCEDURE sp_atomic_device_borrow(
    IN p_device_id BIGINT,
    IN p_borrower_id BIGINT,
    IN p_expect_return_date DATE,
    OUT p_result INT
)
BEGIN
    DECLARE v_status VARCHAR(20);

    -- 获取设备状态
    SELECT status INTO v_status FROM device WHERE id = p_device_id FOR UPDATE;

    IF v_status IS NULL THEN
        SET p_result = -1; -- 设备不存在
    ELSEIF v_status != 'NORMAL' THEN
        SET p_result = -2; -- 设备不可用
    ELSE
        -- 原子更新设备状态
        UPDATE device
        SET status = 'BORROWED',
            borrower_id = p_borrower_id,
            borrow_time = NOW(),
            expect_return_time = p_expect_return_date
        WHERE id = p_device_id;

        -- 插入借用历史
        INSERT INTO device_borrow_history
        (device_id, borrower_id, borrow_time, expect_return_time, status, operation_time, create_time)
        VALUES
        (p_device_id, p_borrower_id, NOW(), p_expect_return_date, 'BORROWING', NOW(), NOW());

        SET p_result = 1; -- 成功
    END IF;
END //
DELIMITER ;

-- 2. 创建耗材库存原子扣减存储过程
DELIMITER //
CREATE PROCEDURE sp_atomic_consumable_out(
    IN p_consumable_id BIGINT,
    IN p_quantity DECIMAL(10,2),
    IN p_operator_id BIGINT,
    IN p_receiver VARCHAR(50),
    IN p_purpose VARCHAR(500),
    OUT p_result INT
)
BEGIN
    DECLARE v_current_stock DECIMAL(10,2);

    -- 获取当前库存（带锁）
    SELECT current_stock INTO v_current_stock
    FROM consumable
    WHERE id = p_consumable_id
    FOR UPDATE;

    IF v_current_stock IS NULL THEN
        SET p_result = -1; -- 耗材不存在
    ELSEIF v_current_stock < p_quantity THEN
        SET p_result = -2; -- 库存不足
    ELSE
        -- 原子扣减库存
        UPDATE consumable
        SET current_stock = current_stock - p_quantity
        WHERE id = p_consumable_id;

        -- 插入出库记录
        INSERT INTO consumable_log
        (consumable_id, operation_type, quantity, operator_id, operation_time, receiver, purpose, create_time)
        VALUES
        (p_consumable_id, 'OUT', p_quantity, p_operator_id, NOW(), p_receiver, p_purpose, NOW());

        SET p_result = 1; -- 成功
    END IF;
END //
DELIMITER ;

-- 3. 创建预约冲突检测存储过程（带悲观锁）
DELIMITER //
CREATE PROCEDURE sp_check_reservation_conflict(
    IN p_lab_id BIGINT,
    IN p_reservation_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME,
    OUT p_conflict_count INT
)
BEGIN
    SELECT COUNT(*) INTO p_conflict_count
    FROM reservation
    WHERE lab_id = p_lab_id
      AND reservation_date = p_reservation_date
      AND status = 'APPROVED'
      AND deleted = 0
      AND p_start_time < end_time
      AND p_end_time > start_time
    FOR UPDATE;
END //
DELIMITER ;

-- 验证存储过程创建
SELECT '存储过程创建完成' AS status;
SHOW PROCEDURE STATUS WHERE Db = 'lab_management';
