package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.Lab;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LabMapper extends BaseMapper<Lab> {
}
