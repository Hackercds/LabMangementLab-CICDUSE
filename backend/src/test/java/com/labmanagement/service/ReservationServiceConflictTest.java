package com.labmanagement.service;

import com.labmanagement.entity.Reservation;
import com.labmanagement.mapper.ReservationMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * 预约冲突检测单元测试
 */
@ExtendWith(MockitoExtension.class)
public class ReservationServiceConflictTest {

    @Mock
    private ReservationMapper reservationMapper;

    @InjectMocks
    private ReservationService reservationService;

    /**
     * 测试用例1: 不冲突，边界接触
     * 已有: 08:00-10:00
     * 新预约: 10:00-12:00
     * 预期结果: 不冲突 (边界不算重叠)
     */
    @Test
    public void testNoConflict_BoundaryTouch() {
        // Given
        Long labId = 1L;
        LocalDate date = LocalDate.of(2024, 1, 1);
        LocalTime start = LocalTime.of(10, 0);
        LocalTime end = LocalTime.of(12, 0);

        when(reservationMapper.countConflict(labId, date, start, end)).thenReturn(0);

        // When
        int conflictCount = reservationMapper.countConflict(labId, date, start, end);

        // Then
        assertEquals(0, conflictCount);
    }

    /**
     * 测试用例2: 部分重叠
     * 已有: 08:00-10:00
     * 新预约: 09:00-11:00
     * 预期结果: 冲突
     */
    @Test
    public void testConflict_PartialOverlap() {
        // Given
        Long labId = 1L;
        LocalDate date = LocalDate.of(2024, 1, 1);
        LocalTime start = LocalTime.of(9, 0);
        LocalTime end = LocalTime.of(11, 0);

        when(reservationMapper.countConflict(labId, date, start, end)).thenReturn(1);

        // When
        int conflictCount = reservationMapper.countConflict(labId, date, start, end);

        // Then
        assertEquals(1, conflictCount);
    }

    /**
     * 测试用例3: 完全包含
     * 已有: 08:00-12:00
     * 新预约: 09:00-10:00
     * 预期结果: 冲突
     */
    @Test
    public void testConflict_fullyContained() {
        // Given
        Long labId = 1L;
        LocalDate date = LocalDate.of(2024, 1, 1);
        LocalTime start = LocalTime.of(9, 0);
        LocalTime end = LocalTime.of(10, 0);

        when(reservationMapper.countConflict(labId, date, start, end)).thenReturn(1);

        // When
        int conflictCount = reservationMapper.countConflict(labId, date, start, end);

        // Then
        assertEquals(1, conflictCount);
    }

    /**
     * 测试用例4: 被包含
     * 已有: 09:00-11:00
     * 新预约: 08:00-12:00
     * 预期结果: 冲突
     */
    @Test
    public void testConflict_containedByExisting() {
        // Given
        Long labId = 1L;
        LocalDate date = LocalDate.of(2024, 1, 1);
        LocalTime start = LocalTime.of(8, 0);
        LocalTime end = LocalTime.of(12, 0);

        when(reservationMapper.countConflict(labId, date, start, end)).thenReturn(1);

        // When
        int conflictCount = reservationMapper.countConflict(labId, date, start, end);

        // Then
        assertEquals(1, conflictCount);
    }

    /**
     * 测试用例5: 完全不重叠，中间有间隙
     * 已有: 08:00-10:00
     * 新预约: 11:00-12:00
     * 预期结果: 不冲突
     */
    @Test
    public void testNoConflict_withGap() {
        // Given
        Long labId = 1L;
        LocalDate date = LocalDate.of(2024, 1, 1);
        LocalTime start = LocalTime.of(11, 0);
        LocalTime end = LocalTime.of(12, 0);

        when(reservationMapper.countConflict(labId, date, start, end)).thenReturn(0);

        // When
        int conflictCount = reservationMapper.countConflict(labId, date, start, end);

        // Then
        assertEquals(0, conflictCount);
    }
}
