package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.Device;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface DeviceMapper extends BaseMapper<Device> {

    /**
     * 使用悲观锁查询设备（防止并发竞态）
     */
    @Select("SELECT * FROM device WHERE id = #{id} AND deleted = 0 FOR UPDATE")
    Device selectByIdForUpdate(@Param("id") Long id);
}
