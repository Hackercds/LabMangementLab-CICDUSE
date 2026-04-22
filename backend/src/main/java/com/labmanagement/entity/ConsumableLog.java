package com.labmanagement.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 耗材出入库记录实体类
 */
@Data
@TableName("consumable_log")
public class ConsumableLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 耗材ID
     */
    private Long consumableId;

    /**
     * 操作类型：IN/OUT
     */
    private String operationType;

    /**
     * 数量
     */
    private BigDecimal quantity;

    /**
     * 操作人ID
     */
    private Long operatorId;

    /**
     * 操作时间
     */
    private LocalDateTime operationTime;

    /**
     * 领用人
     */
    private String receiver;

    /**
     * 用途
     */
    private String purpose;

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
