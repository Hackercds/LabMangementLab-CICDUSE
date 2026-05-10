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
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
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

    /**
     * 管理员撤销任意预约（含已审批）
     */
    @Transactional
    public void adminCancel(Long id, Long adminId) {
        Reservation reservation = reservationMapper.selectById(id);
        if (reservation == null) {
            throw new BusinessException(404, "预约不存在");
        }
        if ("CANCELED".equals(reservation.getStatus())) {
            throw new BusinessException(ResultCode.FAIL.getCode(), "预约已取消");
        }
        reservation.setStatus("CANCELED");
        reservation.setUpdateTime(LocalDateTime.now());
        reservationMapper.updateById(reservation);
        operationLogService.log(adminId, "ADMIN_CANCEL", "RESERVATION", "管理员撤销预约: " + id, null);
    }

    /**
     * 管理员代他人创建预约
     */
    @Transactional
    public void createForUser(Reservation reservation, Long targetUserId, Long adminId) {
        User targetUser = userMapper.selectById(targetUserId);
        if (targetUser == null) {
            throw new BusinessException(404, "目标用户不存在");
        }
        reservation.setUserId(targetUserId);
        reservation.setStatus("APPROVED");
        reservation.setCreateTime(LocalDateTime.now());
        reservation.setUpdateTime(LocalDateTime.now());
        reservation.setApproverId(adminId);
        reservation.setApproveTime(LocalDateTime.now());
        reservation.setApproveComment("管理员代申请");
        reservationMapper.insert(reservation);
        operationLogService.log(adminId, "ADMIN_CREATE", "RESERVATION",
                "管理员代用户" + targetUserId + "创建预约: " + reservation.getId(), null);
    }

    /**
     * 某日所有实验室预约概览
     */
    public List<Reservation> overviewByDate(LocalDate date) {
        QueryWrapper<Reservation> wrapper = new QueryWrapper<>();
        wrapper.eq("reservation_date", date).eq("status", "APPROVED").eq("deleted", 0);
        return reservationMapper.selectList(wrapper);
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
            int conflictCount = reservationMapper.countAllConflictsForUpdate(
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

        String beforeSnapshot = JacksonUtil.toJson(reservation);

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

        String afterSnapshot = JacksonUtil.toJson(reservation);

        operationLogService.logWithSnapshot(approverId, "APPROVE", "RESERVATION",
                "强制审批预约: " + id + "，取消了 " + canceledConflicts.size() + " 个冲突预约", null,
                beforeSnapshot, afterSnapshot);

        return canceledConflicts;
    }

    public List<Reservation> getConflicts(Long labId, LocalDate date, LocalTime startTime, LocalTime endTime, Long excludeId) {
        return reservationMapper.findConflicts(labId, date, startTime, endTime, excludeId);
    }

    /**
     * 批量Excel导入预约（管理员专用，直接通过）
     * Excel格式: 实验室ID | 日期 | 开始时间 | 结束时间 | 事由 | 人数 | 用户ID
     */
    @Transactional
    public List<String> batchImport(MultipartFile file, Long adminId) {
        List<String> results = new ArrayList<>();
        DateTimeFormatter dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        DateTimeFormatter timeFmt = DateTimeFormatter.ofPattern("HH:mm");

        int success = 0, skip = 0, fail = 0;
        try (InputStream is = file.getInputStream(); Workbook workbook = new XSSFWorkbook(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                // 检查必填列是否为空
                if (isCellEmpty(row.getCell(0)) || isCellEmpty(row.getCell(1)) ||
                    isCellEmpty(row.getCell(2)) || isCellEmpty(row.getCell(3)) || isCellEmpty(row.getCell(5))) {
                    results.add("行" + (i + 1) + ": 跳过 - 缺少必填字段（实验室ID/日期/开始/结束/用户ID）");
                    skip++;
                    continue;
                }

                try {
                    Cell labCell = row.getCell(0);
                    Long labId = labCell.getCellType() == CellType.NUMERIC ? (long) labCell.getNumericCellValue() : Long.parseLong(labCell.getStringCellValue().trim());
                    LocalDate date = parseDateCell(row.getCell(1));
                    LocalTime start = parseTimeCell(row.getCell(2));
                    LocalTime end = parseTimeCell(row.getCell(3));
                    String purpose = getCellString(row.getCell(4));
                    Cell userCell = row.getCell(5);
                    Long userId = userCell.getCellType() == CellType.NUMERIC ? (long) userCell.getNumericCellValue() : Long.parseLong(userCell.getStringCellValue().trim());

                    int conflict = reservationMapper.countConflict(labId, date, start, end);
                    if (conflict > 0) {
                        results.add("行" + (i + 1) + ": 跳过 - 与已有预约冲突");
                        skip++;
                        continue;
                    }

                    Reservation r = new Reservation();
                    r.setLabId(labId); r.setUserId(userId); r.setReservationDate(date);
                    r.setStartTime(start); r.setEndTime(end); r.setPurpose(purpose);
                    r.setStatus("APPROVED"); r.setApproverId(adminId);
                    r.setApproveTime(LocalDateTime.now());
                    r.setCreateTime(LocalDateTime.now()); r.setUpdateTime(LocalDateTime.now());
                    reservationMapper.insert(r);
                    results.add("行" + (i + 1) + ": 成功 - 实验室" + labId + " " + date + " " + start + "-" + end);
                    success++;
                } catch (Exception e) {
                    results.add("行" + (i + 1) + ": 错误 - " + e.getMessage());
                    fail++;
                }
            }
        } catch (Exception e) {
            throw new BusinessException(400, "Excel解析失败: " + e.getMessage());
        }
        results.add(0, "总计: " + (success + skip + fail) + " 条 | 成功 " + success + " | 跳过 " + skip + " | 失败 " + fail);
        return results;
    }

    /**
     * 带每周重复的预约创建
     * repeatWeeks: 重复周数(含本周), 1=仅本周, 0或不传=不重复
     */
    @Transactional
    public List<String> createWithRepeat(Reservation reservation, Long userId, int repeatWeeks) {
        List<String> results = new ArrayList<>();
        LocalDate startDate = reservation.getReservationDate();
        DayOfWeek targetDay = startDate.getDayOfWeek();

        for (int w = 0; w < repeatWeeks; w++) {
            LocalDate date = startDate.plusWeeks(w);
            // 验证是同一天（防止跨月边界问题）
            if (date.getDayOfWeek() != targetDay) continue;

            int conflict = reservationMapper.countConflict(
                    reservation.getLabId(), date,
                    reservation.getStartTime(), reservation.getEndTime());
            if (conflict > 0) {
                results.add(date + ": 冲突已跳过");
                continue;
            }

            Reservation r = new Reservation();
            r.setLabId(reservation.getLabId()); r.setUserId(userId);
            r.setReservationDate(date);
            r.setStartTime(reservation.getStartTime());
            r.setEndTime(reservation.getEndTime());
            r.setPurpose(reservation.getPurpose());
            r.setParticipantCount(reservation.getParticipantCount());
            r.setStatus("APPROVED");
            r.setApproverId(userId);
            r.setApproveTime(LocalDateTime.now());
            r.setCreateTime(LocalDateTime.now()); r.setUpdateTime(LocalDateTime.now());
            reservationMapper.insert(r);
            results.add(date + ": 创建成功");
        }
        operationLogService.log(userId, "BATCH_CREATE", "RESERVATION",
                "批量创建预约(" + repeatWeeks + "周): 实验室" + reservation.getLabId(), null);
        return results;
    }

    private boolean isCellEmpty(Cell cell) {
        return cell == null || cell.getCellType() == CellType.BLANK || (cell.getCellType() == CellType.STRING && cell.getStringCellValue().trim().isEmpty());
    }

    private LocalDate parseDateCell(Cell cell) {
        if (cell.getCellType() == CellType.NUMERIC) {
            return cell.getLocalDateTimeCellValue().toLocalDate();
        }
        return LocalDate.parse(cell.getStringCellValue().trim());
    }

    private LocalTime parseTimeCell(Cell cell) {
        if (cell.getCellType() == CellType.NUMERIC) {
            return cell.getLocalDateTimeCellValue().toLocalTime();
        }
        String s = cell.getStringCellValue().trim();
        return s.length() == 5 ? LocalTime.parse(s) : LocalTime.parse(s, DateTimeFormatter.ofPattern("H:mm"));
    }

    private String getCellString(Cell cell) {
        if (cell == null) return "";
        if (cell.getCellType() == CellType.STRING) return cell.getStringCellValue();
        if (cell.getCellType() == CellType.NUMERIC) return String.valueOf((long) cell.getNumericCellValue());
        return "";
    }
}
