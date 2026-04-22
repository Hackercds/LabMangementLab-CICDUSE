package com.labmanagement.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 设备实体类
 */
@Data
@TableName("device")
public class Device {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 设备名称
     */
    private String name;

    /**
     * 型号
     */
    private String model;

    /**
     * 序列号
     */
    private String serialNumber;

    /**
     * 所属实验室ID
     */
    private Long labId;

    /**
     * 购买日期
     */
    private LocalDate purchaseDate;

    /**
     * 状态：NORMAL/BORROWED/MAINTENANCE/SCRAPPED
     */
    private String status;

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
    private LocalDateTime returnTime;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    private LocalDateTime updateTime;

    /**
     * 备注
     */
    private String remark;

    /**
     * 逻辑删除
     */
    @TableLogic
    private Integer deleted;
}
