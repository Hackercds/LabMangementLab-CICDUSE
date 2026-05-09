package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.Consumable;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ConsumableMapper extends BaseMapper<Consumable> {

    /**
     * 使用悲观锁查询耗材（防止并发竞态）
     */
    @Select("SELECT * FROM consumable WHERE id = #{id} AND deleted = 0 FOR UPDATE")
    Consumable selectByIdForUpdate(@Param("id") Long id);

    /**
     * 查询低库存（低于预警阈值）的耗材列表
     */
    @Select("SELECT * FROM consumable WHERE current_stock <= warning_threshold AND warning_threshold > 0 AND deleted = 0")
    List<Consumable> selectLowStockList();
}
