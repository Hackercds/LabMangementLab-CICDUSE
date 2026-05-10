package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.labmanagement.entity.*;
import com.labmanagement.mapper.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final LabMapper labMapper;
    private final ReservationMapper reservationMapper;
    private final DeviceMapper deviceMapper;
    private final ConsumableMapper consumableMapper;
    private final UserMapper userMapper;

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
        private List<ReservationDetail> reservations;
    }

    @Data
    public static class ReservationDetail {
        private Long id;
        private String date;
        private String startTime;
        private String endTime;
        private String purpose;
        private String username;
        private String realName;
    }

    @Data
    public static class DeviceBorrowStats {
        private String deviceName;
        private String labName;
        private Long borrowCount;
    }

    public DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();
        LocalDate today = LocalDate.now();

        LambdaQueryWrapper<Reservation> tw = new LambdaQueryWrapper<>();
        tw.eq(Reservation::getReservationDate, today);
        stats.setTodayReservationCount(Math.toIntExact(reservationMapper.selectCount(tw)));

        LambdaQueryWrapper<Reservation> pw = new LambdaQueryWrapper<>();
        pw.eq(Reservation::getStatus, "PENDING");
        stats.setPendingApprovalCount(Math.toIntExact(reservationMapper.selectCount(pw)));

        LambdaQueryWrapper<Device> dw = new LambdaQueryWrapper<>();
        dw.eq(Device::getStatus, "BORROWED");
        stats.setBorrowedDeviceCount(Math.toIntExact(deviceMapper.selectCount(dw)));

        stats.setLowStockConsumableCount(consumableMapper.selectLowStockList().size());

        List<Lab> labs = labMapper.selectList(null);
        if (!labs.isEmpty()) {
            BigDecimal totalRate = BigDecimal.ZERO;
            for (Lab lab : labs) {
                LambdaQueryWrapper<Reservation> rw = new LambdaQueryWrapper<>();
                rw.eq(Reservation::getLabId, lab.getId()).eq(Reservation::getStatus, "APPROVED");
                long count = reservationMapper.selectCount(rw);
                BigDecimal rate = BigDecimal.valueOf(Math.min(count * 2 / 30.0, 1.0)).multiply(BigDecimal.valueOf(100));
                totalRate = totalRate.add(rate);
            }
            stats.setLabUsageRate(totalRate.divide(BigDecimal.valueOf(labs.size()), 2, BigDecimal.ROUND_HALF_UP));
        } else {
            stats.setLabUsageRate(BigDecimal.ZERO);
        }
        return stats;
    }

    public List<LabUsageStats> getLabUsage(LocalDate startDate, LocalDate endDate) {
        List<Lab> labs = labMapper.selectList(null);
        List<LabUsageStats> result = new ArrayList<>();
        DateTimeFormatter tf = DateTimeFormatter.ofPattern("HH:mm");

        for (Lab lab : labs) {
            LambdaQueryWrapper<Reservation> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(Reservation::getLabId, lab.getId())
                    .eq(Reservation::getStatus, "APPROVED")
                    .between(Reservation::getReservationDate, startDate, endDate)
                    .orderByAsc(Reservation::getReservationDate);

            List<Reservation> reservations = reservationMapper.selectList(wrapper);
            int totalHours = 0;
            List<ReservationDetail> details = new ArrayList<>();
            for (Reservation r : reservations) {
                int hours = r.getEndTime().getHour() - r.getStartTime().getHour();
                totalHours += hours;
                ReservationDetail d = new ReservationDetail();
                d.setId(r.getId());
                d.setDate(r.getReservationDate().toString());
                d.setStartTime(r.getStartTime().format(tf));
                d.setEndTime(r.getEndTime().format(tf));
                d.setPurpose(r.getPurpose());
                User u = userMapper.selectById(r.getUserId());
                d.setUsername(u != null ? u.getUsername() : "");
                d.setRealName(u != null ? u.getRealName() : "");
                details.add(d);
            }

            long days = endDate.toEpochDay() - startDate.toEpochDay() + 1;
            int availableHoursPerDay = 8;
            int totalAvailableHours = (int) (days * availableHoursPerDay);
            BigDecimal usageRate = BigDecimal.valueOf(totalAvailableHours > 0 ? totalHours * 100.0 / totalAvailableHours : 0)
                    .setScale(2, BigDecimal.ROUND_HALF_UP);

            LabUsageStats stat = new LabUsageStats();
            stat.setLabName(lab.getName());
            stat.setTotalReservations((long) reservations.size());
            stat.setTotalHours(totalHours);
            stat.setUsageRate(usageRate);
            stat.setReservations(details);
            result.add(stat);
        }
        return result;
    }

    public List<DeviceBorrowStats> getDeviceBorrowStats(LocalDate startDate, LocalDate endDate) {
        List<Device> devices = deviceMapper.selectList(null);
        List<DeviceBorrowStats> result = new ArrayList<>();
        for (Device device : devices) {
            Lab lab = labMapper.selectById(device.getLabId());
            DeviceBorrowStats stat = new DeviceBorrowStats();
            stat.setDeviceName(device.getName());
            stat.setLabName(lab != null ? lab.getName() : "");
            stat.setBorrowCount(0L);
            result.add(stat);
        }
        return result;
    }

    public byte[] exportLabUsageToExcel(List<LabUsageStats> stats) throws IOException {
        Workbook workbook = new XSSFWorkbook();
        Sheet sheet = workbook.createSheet("实验室使用率统计");

        CellStyle headerStyle = workbook.createCellStyle();
        Font headerFont = workbook.createFont();
        headerFont.setBold(true);
        headerStyle.setFont(headerFont);

        String[] headers = {"实验室名称", "日期", "时间段", "事由", "预约人", "预约次数", "总使用小时", "使用率(%)"};
        Row headerRow = sheet.createRow(0);
        for (int i = 0; i < headers.length; i++) {
            Cell cell = headerRow.createCell(i);
            cell.setCellValue(headers[i]);
            cell.setCellStyle(headerStyle);
        }

        int rowIdx = 1;
        for (LabUsageStats stat : stats) {
            if (stat.getReservations() != null && !stat.getReservations().isEmpty()) {
                for (ReservationDetail d : stat.getReservations()) {
                    Row row = sheet.createRow(rowIdx++);
                    row.createCell(0).setCellValue(stat.getLabName());
                    row.createCell(1).setCellValue(d.getDate());
                    row.createCell(2).setCellValue(d.getStartTime() + "-" + d.getEndTime());
                    row.createCell(3).setCellValue(d.getPurpose());
                    row.createCell(4).setCellValue(d.getRealName() + "(" + d.getUsername() + ")");
                }
            }
            // 汇总行
            Row sumRow = sheet.createRow(rowIdx++);
            sumRow.createCell(0).setCellValue(stat.getLabName() + " 汇总");
            sumRow.createCell(5).setCellValue(stat.getTotalReservations());
            sumRow.createCell(6).setCellValue(stat.getTotalHours());
            sumRow.createCell(7).setCellValue(stat.getUsageRate().doubleValue());
        }

        for (int i = 0; i < headers.length; i++) sheet.autoSizeColumn(i);

        ByteArrayOutputStream os = new ByteArrayOutputStream();
        workbook.write(os);
        workbook.close();
        return os.toByteArray();
    }
}
