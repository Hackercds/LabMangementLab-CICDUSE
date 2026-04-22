package com.labmanagement.controller;

import com.labmanagement.common.result.Result;
import com.labmanagement.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

/**
 * 数据统计控制器
 */
@Slf4j
@RestController
@RequestMapping("/statistics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class StatisticsController {

    private final StatisticsService statisticsService;

    /**
     * 仪表盘统计数据
     */
    @GetMapping("/dashboard")
    public Result<StatisticsService.DashboardStats> dashboard() {
        StatisticsService.DashboardStats stats = statisticsService.getDashboardStats();
        return Result.success(stats);
    }

    /**
     * 实验室使用率统计
     */
    @GetMapping("/lab-usage")
    public Result<List<StatisticsService.LabUsageStats>> labUsage(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<StatisticsService.LabUsageStats> stats = statisticsService.getLabUsage(startDate, endDate);
        return Result.success(stats);
    }

    /**
     * 设备借用频次统计
     */
    @GetMapping("/device-borrow")
    public Result<List<StatisticsService.DeviceBorrowStats>> deviceBorrow(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<StatisticsService.DeviceBorrowStats> stats = statisticsService.getDeviceBorrowStats(startDate, endDate);
        return Result.success(stats);
    }

    /**
     * 导出实验室使用率统计到Excel
     */
    @GetMapping("/export/lab-usage")
    public ResponseEntity<byte[]> exportLabUsage(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) throws IOException {
        List<StatisticsService.LabUsageStats> stats = statisticsService.getLabUsage(startDate, endDate);
        byte[] data = statisticsService.exportLabUsageToExcel(stats);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        headers.setContentDispositionFormData("attachment",
                "lab-usage-" + startDate + "-" + endDate + ".xlsx");

        return ResponseEntity.ok()
                .headers(headers)
                .body(data);
    }
}
