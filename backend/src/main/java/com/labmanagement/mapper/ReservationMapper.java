package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.Reservation;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Mapper
public interface ReservationMapper extends BaseMapper<Reservation> {

    /**
     * 检测时间段是否冲突
     * 条件：同一实验室、同一日期、时间段重叠、状态为已通过
     * 重叠条件：新开始 < 已有结束 && 新结束 > 已有开始
     */
    @Select("SELECT COUNT(*) FROM reservation WHERE lab_id = #{labId} AND reservation_date = #{date} " +
            "AND status = 'APPROVED' AND deleted = 0 " +
            "AND #{startTime} < end_time AND #{endTime} > start_time")
    int countConflict(@Param("labId") Long labId, @Param("date") LocalDate date,
                      @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime);

    /**
     * 查询指定日期某实验室已占用时间段
     */
    @Select("SELECT start_time, end_time FROM reservation WHERE lab_id = #{labId} " +
            "AND reservation_date = #{date} AND status = 'APPROVED' AND deleted = 0")
    List<BusyTime> findBusyTimes(@Param("labId") Long labId, @Param("date") LocalDate date);

    /**
     * 已占用时间段投影
     */
    interface BusyTime {
        LocalTime getStartTime();
        LocalTime getEndTime();
    }
}
