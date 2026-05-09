package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.DeviceBorrowHistory;
import org.apache.ibatis.annotations.Mapper;

/**
 * 设备借用历史Mapper接口
 */
@Mapper
public interface DeviceBorrowHistoryMapper extends BaseMapper<DeviceBorrowHistory> {
}
