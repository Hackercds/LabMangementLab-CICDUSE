package com.labmanagement.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 实验室实体类
 */
@Data
@TableName("lab")
public class Lab {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 实验室名称
     */
    private String name;

    /**
     * 位置
     */
    private String location;

    /**
     * 容纳人数
     */
    private Integer capacity;

    /**
     * 设备数量
     */
    private Integer deviceCount;

    /**
     * 当前状态：FREE/OCCUPIED/MAINTENANCE
     */
    private String status;

    /**
     * 负责人
     */
    private String director;

    /**
     * 联系电话
     */
    private String phone;

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
