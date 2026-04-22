package com.labmanagement.service;

import com.labmanagement.entity.Consumable;
import com.labmanagement.entity.Reservation;
import com.labmanagement.entity.Device;
import com.labmanagement.mapper.ConsumableMapper;
import com.labmanagement.mapper.ReservationMapper;
import com.labmanagement.mapper.DeviceMapper;
import com.labmanagement.mapper.LabMapper;
import com.labmanagement.entity.Lab;
import lombok.RequiredArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.xssf.usermodel.XSSFCell;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 数据统计服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final LabMapper labMapper;
    private final ReservationMapper reservationMapper;
    private final DeviceMapper deviceMapper;
    private final ConsumableMapper consumableMapper;

    @Data
    public static class DashboardStats {
        private Integer todayReservationCount;
        private Integer pendingApprovalCount;
        private Integer borrowedDeviceCount;
        private Integer lowStockConsumableCount;
        private BigDecimal labUsageRate;
    }

    @Data
    public static class LabUsageStats {
        private String labName;
        private Long totalReservations;
        private Integer totalHours;
        private BigDecimal usageRate;
    }

    @Data
    public static class DeviceBorrowStats {
        private String deviceName;
        private String labName;
        private Long borrowCount;
    }

    @Data
    public static class ConsumableTrendStats {
        private String month;
        private BigDecimal totalOut;
    }

    /**
     * 仪表盘统计
     */
    public DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();

        // 今日预约数
        LocalDate today = LocalDate.now();
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Reservation> todayWrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        todayWrapper.eq(Reservation::getReservationDate, today);
        stats.setTodayReservationCount(Math.toIntExact(reservationMapper.selectCount(todayWrapper)));

        // 待审批数
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Reservation> pendingWrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        pendingWrapper.eq(Reservation::getStatus, "PENDING");
        stats.setPendingApprovalCount(Math.toIntExact(reservationMapper.selectCount(pendingWrapper)));

        // 借用中设备数
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Device> borrowWrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        borrowWrapper.eq(Device::getStatus, "BORROWED");
        stats.setBorrowedDeviceCount(Math.toIntExact(deviceMapper.selectCount(borrowWrapper)));

        // 低库存耗材数
        List<Consumable> lowStockList = consumableMapper.selectLowStockList();
        stats.setLowStockConsumableCount(lowStockList.size());

        // 计算实验室平均使用率
        List<Lab> labs = labMapper.selectList(null);
        if (!labs.isEmpty()) {
            BigDecimal totalRate = BigDecimal.ZERO;
            for (Lab lab : labs) {
                // 简单计算，实际应该按时间段统计
                com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Reservation> rw =
                        new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                rw.eq(Reservation::getLabId, lab.getId()).eq(Reservation::getStatus, "APPROVED");
                long count = reservationMapper.selectCount(rw);
                // 简化计算，这里只做示例
                BigDecimal rate = BigDecimal.valueOf(Math.min(count * 2 / 30.0, 1.0))
                        .multiply(BigDecimal.valueOf(100));
                totalRate = totalRate.add(rate);
            }
            stats.setLabUsageRate(totalRate.divide(BigDecimal.valueOf(labs.size()), 2, BigDecimal.ROUND_HALF_UP));
        } else {
            stats.setLabUsageRate(BigDecimal.ZERO);
        }

        return stats;
    }

    /**
     * 实验室使用率统计
     */
    public List<LabUsageStats> getLabUsage(LocalDate startDate, LocalDate endDate) {
        List<Lab> labs = labMapper.selectList(null);
        List<LabUsageStats> result = new ArrayList<>();

        for (Lab lab : labs) {
            com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Reservation> wrapper =
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
            wrapper.eq(Reservation::getLabId, lab.getId())
                    .eq(Reservation::getStatus, "APPROVED")
                    .between(Reservation::getReservationDate, startDate, endDate);

            List<Reservation> reservations = reservationMapper.selectList(wrapper);
            int totalHours = 0;
            for (Reservation r : reservations) {
                int hours = r.getEndTime().getHour() - r.getStartTime().getHour();
                totalHours += hours;
            }

            // 计算使用率: 实际使用小时数 / 总可用小时数
            long days = endDate.toEpochDay() - startDate.toEpochDay() + 1;
            int availableHoursPerDay = 8; // 假设每天可用8小时
            int totalAvailableHours = (int) (days * availableHoursPerDay);
            BigDecimal usageRate = BigDecimal.valueOf(totalHours * 100.0 / totalAvailableHours)
                    .setScale(2, BigDecimal.ROUND_HALF_UP);

            LabUsageStats stat = new LabUsageStats();
            stat.setLabName(lab.getName());
            stat.setTotalReservations((long) reservations.size());
            stat.setTotalHours(totalHours);
            stat.setUsageRate(usageRate);
            result.add(stat);
        }

        result.sort((a, b) -> b.getUsageRate().compareTo(a.getUsageRate()));
        return result;
    }

    /**
     * 设备借用频次统计
     */
    public List<DeviceBorrowStats> getDeviceBorrowStats(LocalDate startDate, LocalDate endDate) {
        List<Device> devices = deviceMapper.selectList(null);
        Map<Long, Long> borrowCountMap = new HashMap<>();

        // 这里简化处理，实际可以通过SQL统计
        for (Device device : devices) {
            // 统计次数，这里简化
            borrowCountMap.put(device.getId(), 0L);
        }

        // 查询时间段内已归还的借用记录，统计每个设备的借用次数
        // 简化实现，返回按借用次数排序
        List<DeviceBorrowStats> result = new ArrayList<>();
        for (Device device : devices) {
            Lab lab = labMapper.selectById(device.getLabId());
            DeviceBorrowStats stat = new DeviceBorrowStats();
            stat.setDeviceName(device.getName());
            stat.setLabName(lab != null ? lab.getName() : "");
            // 简化：这里只演示结构，实际统计需要关联查询
            stat.setBorrowCount(borrowCountMap.getOrDefault(device.getId(), 0L));
            result.add(stat);
        }

        result.sort((a, b) -> Long.compare(b.getBorrowCount(), a.getBorrowCount()));
        return result;
    }

    /**
     * 导出统计数据为Excel
     */
    public byte[] exportLabUsageToExcel(List<LabUsageStats> stats) throws IOException {
        XSSFWorkbook workbook = new XSSFWorkbook();
        XSSFSheet sheet = workbook.createSheet("实验室使用率统计");

        // 表头
        XSSFRow headerRow = sheet.createRow(0);
        String[] headers = {"实验室名称", "预约次数", "总使用小时", "使用率(%)"};
        for (int i = 0; i < headers.length; i++) {
            XSSFCell cell = headerRow.createCell(i);
            cell.setCellValue(headers[i]);
        }

        // 数据
        for (int i = 0; i < stats.size(); i++) {
            XSSFRow row = sheet.createRow(i + 1);
            LabUsageStats stat = stats.get(i);
            row.createCell(0).setCellValue(stat.getLabName());
            row.createCell(1).setCellValue(stat.getTotalReservations());
            row.createCell(2).setCellValue(stat.getTotalHours());
            row.createCell(3).setCellValue(stat.getUsageRate().doubleValue());
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        workbook.write(outputStream);
        workbook.close();
        return outputStream.toByteArray();
    }
}
