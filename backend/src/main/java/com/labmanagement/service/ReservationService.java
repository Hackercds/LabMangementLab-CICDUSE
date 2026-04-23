package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.common.result.ResultCode;
import com.labmanagement.entity.Reservation;
import com.labmanagement.entity.User;
import com.labmanagement.mapper.ReservationMapper;
import lombok.RequiredArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 预约管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReservationService {

    private final ReservationMapper reservationMapper;
    private final OperationLogService operationLogService;

    @Data
    public static class BusyTime {
        private LocalTime startTime;
        private LocalTime endTime;
    }

    /**
     * 查询指定日期某实验室的已占用时间段
     */
    public List<BusyTime> getBusyTimes(Long labId, LocalDate date) {
        List<ReservationMapper.BusyTime> busyTimes = reservationMapper.findBusyTimes(labId, date);
        return busyTimes.stream().map(t -> {
            BusyTime bt = new BusyTime();
            bt.setStartTime(t.getStartTime());
            bt.setEndTime(t.getEndTime());
            return bt;
        }).collect(Collectors.toList());
    }

    /**
     * 获取当前用户的预约列表
     */
    public IPage<Reservation> getMyReservations(Integer current, Integer size, Long userId) {
        Page<Reservation> page = new Page<>(current, size);
        LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Reservation::getUserId, userId)
                .orderByDesc(Reservation::getCreateTime);
        return reservationMapper.selectPage(page, wrapper);
    }

    /**
     * 管理端分页查询
     */
    public IPage<Reservation> pageList(Integer current, Integer size, Long labId, Long userId, String status, LocalDate date) {
        Page<Reservation> page = new Page<>(current, size);
        LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(Reservation::getCreateTime);

        if (labId != null) {
            wrapper.eq(Reservation::getLabId, labId);
        }
        if (userId != null) {
            wrapper.eq(Reservation::getUserId, userId);
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(Reservation::getStatus, status);
        }
        if (date != null) {
            wrapper.eq(Reservation::getReservationDate, date);
        }

        return reservationMapper.selectPage(page, wrapper);
    }

    /**
     * 获取预约详情
     */
    public Reservation getById(Long id) {
        return reservationMapper.selectById(id);
    }

    /**
     * 提交预约申请
     */
    @Transactional
    public void create(Reservation reservation, Long userId) {
        // 检测冲突
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
        reservationMapper.insert(reservation);

        operationLogService.log(userId, "CREATE", "RESERVATION",
                "提交预约申请: labId=" + reservation.getLabId() +
                        ", date=" + reservation.getReservationDate(), null);
    }

    /**
     * 用户取消预约
     */
    @Transactional
    public void cancel(Long id, Long userId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }
        if (!reservation.getUserId().equals(userId)) {
            throw new BusinessException(ResultCode.FORBIDDEN);
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        reservation.setStatus("CANCELED");
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);

        operationLogService.log(userId, "CANCEL", "RESERVATION", "取消预约: " + id, null);
    }

    /**
     * 审批预约
     */
    @Transactional
    public void approve(Long id, String status, String comment, Long approverId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        // 如果是批准，需要再次检测冲突（防止并发情况下已经被其他审批通过了
        if ("APPROVED".equals(status)) {
            int conflictCount = reservationMapper.countConflict(
                    reservation.getLabId(),
                    reservation.getReservationDate(),
                    reservation.getStartTime(),
                    reservation.getEndTime()
            );
            if (conflictCount > 0) {
                throw new BusinessException(ResultCode.TIME_CONFLICT);
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

    /**
     * 查询冲突的预约
     */
    public List<Reservation> getConflicts(Long labId, LocalDate date, LocalTime startTime, LocalTime endTime, Long excludeId) {
        return reservationMapper.findConflicts(labId, date, startTime, endTime, excludeId);
    }

    /**
     * 强制审批预约（当存在冲突时，自动将冲突的预约设为拒绝）
     * @return 被取消的冲突预约列表
     */
    @Transactional
    public List<Reservation> forceApprove(Long id, String comment, Long approverId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.RESERVATION_ALREADY_PROCESSED);
        }

        // 查询冲突的预约
        List<Reservation> conflicts = reservationMapper.findConflicts(
                reservation.getLabId(),
                reservation.getReservationDate(),
                reservation.getStartTime(),
                reservation.getEndTime(),
                id
        );

        // 将所有冲突的已审批预约设为拒绝
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

        // 审批当前预约
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
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return ((User) principal).getId();
        }
        return null;
    }
}
