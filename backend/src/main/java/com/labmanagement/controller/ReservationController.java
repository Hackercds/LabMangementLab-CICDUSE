package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.common.exception.ConflictException;
import com.labmanagement.common.result.Result;
import com.labmanagement.common.result.ResultCode;
import com.labmanagement.entity.Reservation;
import com.labmanagement.mapper.ReservationMapper;
import com.labmanagement.service.ReservationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
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
    public Result<List<ReservationMapper.BusyTime>> getBusyTimes(
            @RequestParam Long labId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<ReservationMapper.BusyTime> busyTimes = reservationService.getBusyTimes(labId, date);
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
        try {
            reservationService.approve(id, status, comment, userId);
            return Result.success();
        } catch (BusinessException e) {
            if (ResultCode.TIME_CONFLICT.getCode().equals(e.getCode())) {
                // 查询冲突的预约详情
                Reservation current = reservationService.getById(id);
                List<Reservation> conflicts = reservationService.getConflicts(
                        current.getLabId(),
                        current.getReservationDate(),
                        current.getStartTime(),
                        current.getEndTime(),
                        id
                );
                throw new ConflictException(e.getMessage(), conflicts);
            }
            throw e;
        }
    }

    /**
     * 管理员撤销任意预约
     */
    @PutMapping("/{id}/admin-cancel")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> adminCancel(@PathVariable Long id, @RequestAttribute Long userId) {
        reservationService.adminCancel(id, userId);
        return Result.success();
    }

    /**
     * 管理员代他人创建预约（直接通过，不走审批）
     */
    @PostMapping("/admin-create")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> adminCreate(@RequestParam Long targetUserId,
                                     @RequestParam Long labId,
                                     @RequestParam String reservationDate,
                                     @RequestParam String startTime,
                                     @RequestParam String endTime,
                                     @RequestParam(required = false) String purpose,
                                     @RequestAttribute Long userId) {
        Reservation reservation = new Reservation();
        reservation.setLabId(labId);
        reservation.setReservationDate(LocalDate.parse(reservationDate));
        reservation.setStartTime(java.time.LocalTime.parse(startTime));
        reservation.setEndTime(java.time.LocalTime.parse(endTime));
        reservation.setPurpose(purpose);
        reservationService.createForUser(reservation, targetUserId, userId);
        return Result.success();
    }

    /**
     * 某日全实验室预约概览
     */
    @GetMapping("/overview")
    public Result<List<Reservation>> overview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<Reservation> list = reservationService.overviewByDate(date);
        return Result.success(list);
    }

    /**
     * 下载Excel导入模板
     */
    @GetMapping("/batch-template")
    public ResponseEntity<ByteArrayResource> downloadTemplate() throws IOException {
        Workbook wb = new XSSFWorkbook();
        Sheet sheet = wb.createSheet("预约导入");
        Row header = sheet.createRow(0);
        String[] cols = {"实验室ID", "日期(YYYY-MM-DD)", "开始时间(HH:MM)", "结束时间(HH:MM)", "事由", "用户ID"};
        for (int i = 0; i < cols.length; i++) {
            Cell cell = header.createCell(i); cell.setCellValue(cols[i]);
            CellStyle style = wb.createCellStyle();
            Font font = wb.createFont(); font.setBold(true);
            style.setFont(font); cell.setCellStyle(style);
            sheet.setColumnWidth(i, 4000);
        }
        // 示例行
        Row example = sheet.createRow(1);
        example.createCell(0).setCellValue(1);
        example.createCell(1).setCellValue("2026-05-15");
        example.createCell(2).setCellValue("08:00");
        example.createCell(3).setCellValue("10:00");
        example.createCell(4).setCellValue("示例课程");
        example.createCell(5).setCellValue(2);

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        wb.write(bos); wb.close();
        byte[] bytes = bos.toByteArray();

        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=reservation-template.xlsx");
        return ResponseEntity.ok().headers(headers).contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(new ByteArrayResource(bytes));
    }

    /**
     * 批量Excel导入预约（管理员）
     */
    @PostMapping("/batch-import")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<List<String>> batchImport(@RequestParam("file") MultipartFile file,
                                             @RequestAttribute Long userId) {
        List<String> results = reservationService.batchImport(file, userId);
        return Result.success(results);
    }

    /**
     * 每周重复预约
     */
    @PostMapping("/repeat")
    public Result<List<String>> createWithRepeat(@RequestBody Reservation reservation,
                                                  @RequestParam(defaultValue = "1") int repeatWeeks,
                                                  @RequestAttribute Long userId) {
        List<String> results = reservationService.createWithRepeat(reservation, userId, repeatWeeks);
        return Result.success(results);
    }

    /**
     * 强制审批预约（自动取消冲突的预约）
     */
    @PutMapping("/{id}/force-approve")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public Result<List<Reservation>> forceApprove(
            @PathVariable Long id,
            @RequestParam(required = false) String comment,
            @RequestAttribute Long userId) {
        List<Reservation> canceled = reservationService.forceApprove(id, comment, userId);
        return Result.success(canceled);
    }
}
