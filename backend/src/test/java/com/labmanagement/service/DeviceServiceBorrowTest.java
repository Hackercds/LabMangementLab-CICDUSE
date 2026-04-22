package com.labmanagement.service;

import com.labmanagement.entity.Device;
import com.labmanagement.mapper.DeviceMapper;
import com.labmanagement.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * 设备借用状态转换单元测试
 */
@ExtendWith(MockitoExtension.class)
public class DeviceServiceBorrowTest {

    @Mock
    private DeviceMapper deviceMapper;

    @Mock
    private OperationLogService operationLogService;

    @InjectMocks
    private DeviceService deviceService;

    /**
     * 测试用例1: 正常状态设备可借用
     * 当前状态: NORMAL
     * 预期结果: 借用成功，状态变为 BORROWED
     */
    @Test
    public void testBorrow_normalDevice() {
        // Given
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("NORMAL");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectById(id)).thenReturn(device);

        // When
        deviceService.borrow(id, request, 1L);

        // Then
        assertEquals("BORROWED", device.getStatus());
        assertEquals(Long.valueOf(1L), device.getBorrowerId());
        verify(deviceMapper, times(1)).updateById(device);
    }

    /**
     * 测试用例2: 已借用设备不能重复借用
     * 当前状态: BORROWED
     * 预期结果: 抛出异常，借用失败
     */
    @Test
    public void testBorrow_alreadyBorrowed() {
        // Given
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("BORROWED");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectById(id)).thenReturn(device);

        // When & Then
        assertThrows(BusinessException.class, () -> {
            deviceService.borrow(id, request, 1L);
        });

        verify(deviceMapper, never()).updateById(any());
    }

    /**
     * 测试用例3: 维修中设备不能借用
     * 当前状态: MAINTENANCE
     * 预期结果: 抛出异常，借用失败
     */
    @Test
    public void testBorrow_inMaintenance() {
        // Given
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("MAINTENANCE");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectById(id)).thenReturn(device);

        // When & Then
        assertThrows(BusinessException.class, () -> {
            deviceService.borrow(id, request, 1L);
        });

        verify(deviceMapper, never()).updateById(any());
    }

    /**
     * 测试用例4: 归还设备
     * 当前状态: BORROWED
     * 预期结果: 归还成功，状态变回 NORMAL
     */
    @Test
    public void testReturn_success() {
        // Given
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("BORROWED");
        device.setBorrowerId(1L);

        when(deviceMapper.selectById(id)).thenReturn(device);

        // When
        deviceService.returnDevice(id, 1L);

        // Then
        assertEquals("NORMAL", device.getStatus());
        assertNull(device.getBorrowerId());
        assertNotNull(device.getReturnTime());
        verify(deviceMapper, times(1)).updateById(device);
    }

    /**
     * 测试用例5: 归还非借用设备
     * 当前状态: NORMAL
     * 预期结果: 抛出异常
     */
    @Test
    public void testReturn_notBorrowed() {
        // Given
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("NORMAL");

        when(deviceMapper.selectById(id)).thenReturn(device);

        // When & Then
        assertThrows(BusinessException.class, () -> {
            deviceService.returnDevice(id, 1L);
        });

        verify(deviceMapper, never()).updateById(any());
    }
}
