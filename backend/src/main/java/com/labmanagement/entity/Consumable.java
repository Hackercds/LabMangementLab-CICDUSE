package com.labmanagement.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 耗材实体类
 */
@Data
@TableName("consumable")
public class Consumable {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 耗材名称
     */
    private String name;

    /**
     * 规格
     */
    private String specification;

    /**
     * 单位
     */
    private String unit;

    /**
     * 当前库存
     */
    private BigDecimal currentStock;

    /**
     * 预警阈值
     */
    private BigDecimal warningThreshold;

    /**
     * 存放位置
     */
    private String location;

    /**
     * 负责人
     */
    private String director;

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
