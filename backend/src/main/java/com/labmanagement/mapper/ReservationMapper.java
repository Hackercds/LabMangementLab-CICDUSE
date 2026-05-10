package com.labmanagement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.labmanagement.entity.Reservation;
import org.apache.ibatis.annotations.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Mapper
public interface ReservationMapper extends BaseMapper<Reservation> {

    /**
     * 使用悲观锁查询预约（防止并发冲突）
     */
    @Select("SELECT * FROM reservation WHERE id = #{id} AND deleted = 0 FOR UPDATE")
    Reservation selectByIdForUpdate(@Param("id") Long id);

    /**
     * 检测时间段是否冲突（包括所有状态的预约）
     */
    @Select("SELECT COUNT(*) FROM reservation WHERE lab_id = #{labId} AND reservation_date = #{date} " +
            "AND status IN ('APPROVED', 'PENDING') AND deleted = 0 AND id != #{excludeId} " +
            "AND #{startTime} < end_time AND #{endTime} > start_time")
    int countAllConflicts(@Param("labId") Long labId, @Param("date") LocalDate date,
                          @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime,
                          @Param("excludeId") Long excludeId);

    /**
     * 带悲观锁检测时间段冲突（用于审批流程，锁住冲突范围内的行）
     */
    @Select("SELECT COUNT(*) FROM reservation WHERE lab_id = #{labId} AND reservation_date = #{date} " +
            "AND status IN ('APPROVED', 'PENDING') AND deleted = 0 AND id != #{excludeId} " +
            "AND #{startTime} < end_time AND #{endTime} > start_time FOR UPDATE")
    int countAllConflictsForUpdate(@Param("labId") Long labId, @Param("date") LocalDate date,
                                   @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime,
                                   @Param("excludeId") Long excludeId);

    /**
     * 调用存储过程检测冲突（备选方案，与 countAllConflictsForUpdate 等价）
     */
    @Select("CALL sp_check_reservation_conflict(#{labId}, #{date}, #{startTime}, #{endTime}, @conflict_count)")
    void callCheckConflictSp(@Param("labId") Long labId, @Param("date") LocalDate date,
                             @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime);

    /**
     * 检测时间段是否冲突（仅APPROVED状态的预约）
     */
    @Select("SELECT COUNT(*) FROM reservation WHERE lab_id = #{labId} AND reservation_date = #{date} " +
            "AND status = 'APPROVED' AND deleted = 0 " +
            "AND #{startTime} < end_time AND #{endTime} > start_time")
    int countConflict(@Param("labId") Long labId, @Param("date") LocalDate date,
                      @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime);

    /**
     * 查询冲突的预约（包括已通过和待审批）
     */
    @Select("SELECT * FROM reservation WHERE lab_id = #{labId} AND reservation_date = #{date} " +
            "AND status IN ('APPROVED', 'PENDING') AND deleted = 0 " +
            "AND id != #{excludeId} " +
            "AND #{startTime} < end_time AND #{endTime} > start_time")
    List<Reservation> findConflicts(@Param("labId") Long labId, @Param("date") LocalDate date,
                                    @Param("startTime") LocalTime startTime, @Param("endTime") LocalTime endTime,
                                    @Param("excludeId") Long excludeId);

    /**
     * 查询指定日期某实验室已占用时间段
     */
    @Select("SELECT start_time, end_time FROM reservation WHERE lab_id = #{labId} " +
            "AND reservation_date = #{date} AND status = 'APPROVED' AND deleted = 0")
    List<BusyTime> findBusyTimes(@Param("labId") Long labId, @Param("date") LocalDate date);

    class BusyTime {
        private LocalTime startTime;
        private LocalTime endTime;
        public LocalTime getStartTime() { return startTime; }
        public void setStartTime(LocalTime startTime) { this.startTime = startTime; }
        public LocalTime getEndTime() { return endTime; }
        public void setEndTime(LocalTime endTime) { this.endTime = endTime; }
    }
}
