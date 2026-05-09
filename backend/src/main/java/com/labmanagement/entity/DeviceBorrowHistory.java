package com.labmanagement.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 设备借用历史实体类
 *
 * 注意：此表与Device表的borrower_id/borrow_time等字段存在数据冗余
 * 建议：仅使用此表记录完整的借用历史，Device表仅保留当前状态
 */
@Data
@TableName("device_borrow_history")
public class DeviceBorrowHistory {

    /**
     * 记录ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 设备ID
     */
    private Long deviceId;

    /**
     * 借用人ID
     */
    private Long borrowerId;

    /**
     * 借用时间
     */
    private LocalDateTime borrowTime;

    /**
     * 预计归还时间
     */
    private LocalDate expectReturnTime;

    /**
     * 实际归还时间
     */
    private LocalDateTime actualReturnTime;

    /**
     * 审批人ID
     */
    private Long approverId;

    /**
     * 状态：BORROWING(借用中)、RETURNED(已归还)、OVERDUE(超期)
     */
    private String status;

    /**
     * 操作时间
     */
    private LocalDateTime operationTime;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 逻辑删除
     */
    @TableLogic
    private Integer deleted;
}
