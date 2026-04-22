package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.result.Result;
import com.labmanagement.entity.Reservation;
import com.labmanagement.service.ReservationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestAttribute;

import java.time.LocalDate;
import java.util.List;

/**
 * 预约管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/reservation")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    /**
     * 查询指定日期某实验室的已占用时间段
     */
    @GetMapping("/busy")
    public Result<List<ReservationService.BusyTime>> getBusyTimes(
            @RequestParam Long labId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<ReservationService.BusyTime> busyTimes = reservationService.getBusyTimes(labId, date);
        return Result.success(busyTimes);
    }

    /**
     * 获取当前用户我的预约列表
     */
    @GetMapping("/my")
    public Result<IPage<Reservation>> myReservations(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestAttribute Long userId) {
        IPage<Reservation> page = reservationService.getMyReservations(current, size, userId);
        return Result.success(page);
    }

    /**
     * 管理端分页查询
     */
    @GetMapping("/list")
    public Result<IPage<Reservation>> list(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) Long labId,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        IPage<Reservation> page = reservationService.pageList(current, size, labId, userId, status, date);
        return Result.success(page);
    }

    /**
     * 获取预约详情
     */
    @GetMapping("/{id}")
    public Result<Reservation> getById(@PathVariable Long id) {
        Reservation reservation = reservationService.getById(id);
        return Result.success(reservation);
    }

    /**
     * 提交预约申请
     */
    @PostMapping
    public Result<Void> create(@RequestBody Reservation reservation, @RequestAttribute Long userId) {
        reservationService.create(reservation, userId);
        return Result.success();
    }

    /**
     * 用户取消预约
     */
    @PutMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id, @RequestAttribute Long userId) {
        reservationService.cancel(id, userId);
        return Result.success();
    }

    /**
     * 审批预约
     */
    @PutMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public Result<Void> approve(
            @PathVariable Long id,
            @RequestParam String status,
            @RequestParam(required = false) String comment,
            @RequestAttribute Long userId) {
        reservationService.approve(id, status, comment, userId);
        return Result.success();
    }
}
