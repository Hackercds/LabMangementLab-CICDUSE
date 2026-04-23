package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.common.exception.ConflictException;
import com.labmanagement.common.result.ResultCode;
import com.labmanagement.entity.Reservation;
import com.labmanagement.entity.User;
import com.labmanagement.mapper.ReservationMapper;
import com.labmanagement.mapper.UserMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReservationService {

    private final ReservationMapper reservationMapper;
    private final OperationLogService operationLogService;
    private final SystemConfigService systemConfigService;
    private final UserMapper userMapper;

    /**
     * 创建预约
     */
    @Transactional
    public void create(Reservation reservation, Long userId) {
        // 检查是否超过每天最大预约次数
        int maxPerDay = systemConfigService.getIntConfig("max_reservation_per_day", 3);
        int todayCount = countUserReservationsToday(userId);
        if (todayCount >= maxPerDay) {
            throw new BusinessException(ResultCode.FAIL, "今日预约次数已达上限");
        }

        // 检查是否超过最大提前天数
        int maxAdvanceDays = systemConfigService.getIntConfig("max_advance_days", 30);
        LocalDate today = LocalDate.now();
        if (reservation.getReservationDate().isBefore(today) || 
            reservation.getReservationDate().isAfter(today.plusDays(maxAdvanceDays))) {
            throw new BusinessException(ResultCode.FAIL, "预约日期超出允许范围");
        }

        // 检查时间冲突（仅检查已通过的预约）
        int conflictCount = reservationMapper.countConflict(
                reservation.getLabId(),
                reservation.getReservationDate(),
                reservation.getStartTime(),
                reservation.getEndTime()
        );
        if (conflictCount > 0) {
            throw new BusinessException(ResultCode.TIME_CONFLICT);
        }

        reservation.setUserId(userId);
        reservation.setStatus("PENDING");
        reservation.setCreateTime(LocalDateTime.now());
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.insert(reservation);

        operationLogService.log(userId, "CREATE", "RESERVATION", "创建预约", null);
    }

    /**
     * 用户取消预约
     */
    @Transactional
    public void cancel(Long id, Long userId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null || !reservation.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FAIL, "预约不存在或无权操作");
        }
        if ("CANCELED".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.FAIL, "预约已取消");
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.FAIL, "已审批的预约不能取消");
        }

        reservation.setStatus("CANCELED");
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(userId, "CANCEL", "RESERVATION", "取消预约: " + id, null);
    }

    /**
     * 审批预约（升级：支持自动冲突检测、悲观锁、高并发安全）
     */
    @Transactional
    public void approve(Long id, String status, String comment, Long approverId) {
        // 1. 使用悲观锁获取预约，防止并发处理
        Reservation reservation = reservationMapper.selectByIdForUpdate(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }

        // 2. 检查预约状态
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        // 3. 如果是批准，检测冲突（包括所有PENDING和APPROVED状态的预约）
        if ("APPROVED".equals(status)) {
            int conflictCount = reservationMapper.countAllConflicts(
                    reservation.getLabId(),
                    reservation.getReservationDate(),
                    reservation.getStartTime(),
                    reservation.getEndTime(),
                    id
            );
            if (conflictCount > 0) {
                // 有冲突，查询冲突详情
                List<Reservation> conflicts = reservationMapper.findConflicts(
                        reservation.getLabId(),
                        reservation.getReservationDate(),
                        reservation.getStartTime(),
                        reservation.getEndTime(),
                        id
                );

                // 4. 检查是否开启自动审批开关
                boolean autoApprove = systemConfigService.getBooleanConfig("auto_approve_teacher", false);
                
                // 获取当前审批人角色
                User approver = userMapper.selectById(approverId);
                boolean isTeacher = approver != null && "TEACHER".equals(approver.getRole());

                if (autoApprove && isTeacher) {
                    // 自动审批模式：自动拒绝所有冲突的预约
                    for (Reservation conflict : conflicts) {
                        conflict.setStatus("REJECTED");
                        conflict.setApproverId(approverId);
                        conflict.setApproveTime(LocalDateTime.now());
                        conflict.setApproveComment("因新预约冲突被系统自动拒绝");
                        conflict.setUpdateTime(LocalDateTime.now());
                        reservationMapper.updateById(conflict);

                        operationLogService.log(approverId, "REJECT", "RESERVATION",
                                "因冲突自动拒绝预约: " + conflict.getId(), null);
                    }
                    
                    // 审批当前预约
                    reservation.setStatus("APPROVED");
                    reservation.setApproverId(approverId);
                    reservation.setApproveTime(LocalDateTime.now());
                    reservation.setApproveComment(comment);
                    reservation.setUpdateTime(LocalDateTime.now());
                    reservationMapper.updateById(reservation);

                    operationLogService.log(approverId, "APPROVE", "RESERVATION",
                            "自动审批预约: " + id + "，取消了 " + conflicts.size() + " 个冲突预约", null);
                    return;
                } else {
                    // 非自动审批模式：抛出异常，返回冲突详情
                    throw new ConflictException("时间段冲突，存在 " + conflicts.size() + " 个冲突预约", conflicts);
                }
            }
        }

        // 5. 无冲突，正常审批
        reservation.setStatus(status);
        reservation.setApproverId(approverId);
        reservation.setApproveTime(LocalDateTime.now());
        reservation.setApproveComment(comment);
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(approverId, "APPROVE", "RESERVATION",
                "审批预约: " + id + " -> " + status, null);
    }

    /**
     * 获取我的预约列表
     */
    public IPage<Reservation> getMyReservations(Integer current, Integer size, Long userId) {
        Page<Reservation> page = new Page<>(current, size);
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
               .eq("deleted", 0)
               .orderByDesc("create_time");
        return reservationMapper.selectPage(page, wrapper);
    }

    /**
     * 管理端分页查询
     */
    public IPage<Reservation> pageList(Integer current, Integer size, Long labId, Long userId, String status, LocalDate date) {
        Page<Reservation> page = new Page<>(current, size);
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("deleted", 0);
        if (labId != null) {
            wrapper.eq("lab_id", labId);
        }
        if (userId != null) {
            wrapper.eq("user_id", userId);
        }
        if (status != null && !status.isEmpty()) {
            wrapper.eq("status", status);
        }
        if (date != null) {
            wrapper.eq("reservation_date", date);
        }
        wrapper.orderByDesc("create_time");
        return reservationMapper.selectPage(page, wrapper);
    }

    /**
     * 获取预约详情
     */
    public Reservation getById(Long id) {
        return reservationMapper.selectById(id);
    }

    /**
     * 查询指定日期某实验室的已占用时间段
     */
    public List<ReservationMapper.BusyTime> getBusyTimes(Long labId, LocalDate date) {
        return reservationMapper.findBusyTimes(labId, date);
    }

    /**
     * 查询用户今日已预约次数
     */
    public int countUserReservationsToday(Long userId) {
        LocalDate today = LocalDate.now();
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
               .eq("reservation_date", today)
               .eq("deleted", 0)
               .in("status", "PENDING", "APPROVED");
        return Math.toIntExact(reservationMapper.selectCount(wrapper));
    }

    /**
     * 强制审批预约（自动拒绝冲突的预约）
     */
    @Transactional
    public List<Reservation> forceApprove(Long id, String comment, Long approverId) {
        // 1. 使用悲观锁获取预约，防止并发处理
        Reservation reservation = reservationMapper.selectByIdForUpdate(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }

        // 2. 检查预约状态
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        // 3. 查询冲突的预约
        List<Reservation> conflicts = reservationMapper.findConflicts(
                reservation.getLabId(),
                reservation.getReservationDate(),
                reservation.getStartTime(),
                reservation.getEndTime(),
                id
        );

        // 4. 自动拒绝所有冲突的已审批预约
        List<Reservation> canceledConflicts = conflicts.stream()
                .filter(c -> "APPROVED".equals(c.getStatus()))
                .collect(Collectors.toList());

        for (Reservation conflict : canceledConflicts) {
            conflict.setStatus("REJECTED");
            conflict.setApproverId(approverId);
            conflict.setApproveTime(LocalDateTime.now());
            conflict.setApproveComment("因新预约冲突被管理员自动拒绝");
            conflict.setUpdateTime(LocalDateTime.now());
            reservationMapper.updateById(conflict);

            operationLogService.log(approverId, "REJECT", "RESERVATION",
                    "因冲突自动拒绝预约: " + conflict.getId(), null);
        }

        // 5. 审批当前预约
        reservation.setStatus("APPROVED");
        reservation.setApproverId(approverId);
        reservation.setApproveTime(LocalDateTime.now());
        reservation.setApproveComment(comment);
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(approverId, "APPROVE", "RESERVATION",
                "强制审批预约: " + id + "，取消了 " + canceledConflicts.size() + " 个冲突预约", null);

        return canceledConflicts;
    }

    /**
     * 查询冲突的预约
     */
    public List<Reservation> getConflicts(Long labId, LocalDate date, LocalTime startTime, LocalTime endTime, Long excludeId) {
        return reservationMapper.findConflicts(labId, date, startTime, endTime, excludeId);
    }
}
