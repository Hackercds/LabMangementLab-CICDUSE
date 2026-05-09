package com.labmanagement.service;

import com.labmanagement.entity.Device;
import com.labmanagement.mapper.DeviceMapper;
import com.labmanagement.mapper.DeviceBorrowHistoryMapper;
import com.labmanagement.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * 设备借用状态转换单元测试
 */
@ExtendWith(MockitoExtension.class)
public class DeviceServiceBorrowTest {

    @Mock
    private DeviceMapper deviceMapper;

    @Mock
    private DeviceBorrowHistoryMapper deviceBorrowHistoryMapper;

    @Mock
    private OperationLogService operationLogService;

    @InjectMocks
    private DeviceService deviceService;

    @Test
    public void testBorrow_normalDevice() {
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("NORMAL");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectByIdForUpdate(id)).thenReturn(device);

        deviceService.borrow(id, request, 1L);

        assertEquals("BORROWED", device.getStatus());
        verify(deviceMapper, times(1)).updateById(device);
    }

    @Test
    public void testBorrow_alreadyBorrowed() {
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("BORROWED");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectByIdForUpdate(id)).thenReturn(device);

        assertThrows(BusinessException.class, () ->
            deviceService.borrow(id, request, 1L));

        verify(deviceMapper, never()).updateById(any());
    }

    @Test
    public void testBorrow_inMaintenance() {
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("MAINTENANCE");

        DeviceService.BorrowRequest request = new DeviceService.BorrowRequest();
        request.setExpectReturnTime(LocalDate.now().plusDays(7));

        when(deviceMapper.selectByIdForUpdate(id)).thenReturn(device);

        assertThrows(BusinessException.class, () ->
            deviceService.borrow(id, request, 1L));

        verify(deviceMapper, never()).updateById(any());
    }

    @Test
    public void testReturn_success() {
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("BORROWED");

        when(deviceMapper.selectByIdForUpdate(id)).thenReturn(device);

        deviceService.returnDevice(id, 1L);

        assertEquals("NORMAL", device.getStatus());
        verify(deviceMapper, times(1)).updateById(device);
    }

    @Test
    public void testReturn_notBorrowed() {
        Long id = 1L;
        Device device = new Device();
        device.setId(id);
        device.setName("测试设备");
        device.setStatus("NORMAL");

        when(deviceMapper.selectByIdForUpdate(id)).thenReturn(device);

        assertThrows(BusinessException.class, () ->
            deviceService.returnDevice(id, 1L));

        verify(deviceMapper, never()).updateById(any());
    }
}
