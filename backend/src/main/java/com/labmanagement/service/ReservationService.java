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

    @Transactional
    public void create(Reservation reservation, Long userId) {
        int maxPerDay = systemConfigService.getIntConfig("max_reservation_per_day", 3);
        int todayCount = countUserReservationsToday(userId);
        if (todayCount >= maxPerDay) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "今日预约次数已达上限");
        }

        int maxAdvanceDays = systemConfigService.getIntConfig("max_advance_days", 30);
        LocalDate today = LocalDate.now();
        if (reservation.getReservationDate().isBefore(today) ||
            reservation.getReservationDate().isAfter(today.plusDays(maxAdvanceDays))) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "预约日期超出允许范围");
        }

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

    @Transactional
    public void cancel(Long id, Long userId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null || !reservation.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "预约不存在或无权操作");
        }
        if ("CANCELED".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "预约已取消");
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "已审批的预约不能取消");
        }

        reservation.setStatus("CANCELED");
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(userId, "CANCEL", "RESERVATION", "取消预约: " + id, null);
    }

    @Transactional
    public void approve(Long id, String status, String comment, Long approverId) {
        Reservation reservation = reservationMapper.selectByIdForUpdate(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }

        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        if ("APPROVED".equals(status)) {
            int conflictCount = reservationMapper.countAllConflicts(
                    reservation.getLabId(),
                    reservation.getReservationDate(),
                    reservation.getStartTime(),
                    reservation.getEndTime(),
                    id
            );
            if (conflictCount > 0) {
                List<Reservation> conflicts = reservationMapper.findConflicts(
                        reservation.getLabId(),
                        reservation.getReservationDate(),
                        reservation.getStartTime(),
                        reservation.getEndTime(),
                        id
                );

                boolean autoApprove = systemConfigService.getBooleanConfig("auto_approve_teacher", false);

                User approver = userMapper.selectById(approverId);
                boolean isTeacher = approver != null && "TEACHER".equals(approver.getRole());

                if (autoApprove && isTeacher) {
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
                    throw new ConflictException("时间段冲突，存在 " + conflicts.size() + " 个冲突预约", conflicts);
                }
            }
        }

        reservation.setStatus(status);
        reservation.setApproverId(approverId);
        reservation.setApproveTime(LocalDateTime.now());
        reservation.setApproveComment(comment);
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(approverId, "APPROVE", "RESERVATION",
                "审批预约: " + id + " -> " + status, null);
    }

    public IPage<Reservation> getMyReservations(Integer current, Integer size, Long userId) {
        Page<Reservation> page = new Page<>(current, size);
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
               .eq("deleted", 0)
               .orderByDesc("create_time");
        return reservationMapper.selectPage(page, wrapper);
    }

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

    public Reservation getById(Long id) {
        return reservationMapper.selectById(id);
    }

    public List<ReservationMapper.BusyTime> getBusyTimes(Long labId, LocalDate date) {
        return reservationMapper.findBusyTimes(labId, date);
    }

    public int countUserReservationsToday(Long userId) {
        LocalDate today = LocalDate.now();
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
               .eq("reservation_date", today)
               .eq("deleted", 0)
               .in("status", "PENDING", "APPROVED");
        return Math.toIntExact(reservationMapper.selectCount(wrapper));
    }

    @Transactional
    public List<Reservation> forceApprove(Long id, String comment, Long approverId) {
        Reservation reservation = reservationMapper.selectByIdForUpdate(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }

        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        List<Reservation> conflicts = reservationMapper.findConflicts(
                reservation.getLabId(),
                reservation.getReservationDate(),
                reservation.getStartTime(),
                reservation.getEndTime(),
                id
        );

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

    public List<Reservation> getConflicts(Long labId, LocalDate date, LocalTime startTime, LocalTime endTime, Long excludeId) {
        return reservationMapper.findConflicts(labId, date, startTime, endTime, excludeId);
    }
}
