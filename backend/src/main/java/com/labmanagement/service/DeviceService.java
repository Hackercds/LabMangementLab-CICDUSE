package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.common.result.ResultCode;
import com.labmanagement.entity.Device;
import com.labmanagement.mapper.DeviceMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 设备管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceMapper deviceMapper;
    private final OperationLogService operationLogService;

    @lombok.Data
    public static class BorrowRequest {
        private Long deviceId;
        private LocalDate expectReturnTime;
    }

    /**
     * 条件查询列表
     */
    public List<Device> list(Long labId, String status) {
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Device::getId);
        if (labId != null) {
            wrapper.eq(Device::getLabId, labId);
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(Device::getStatus, status);
        }
        return deviceMapper.selectList(wrapper);
    }

    /**
     * 分页查询
     */
    public IPage<Device> pageList(Integer current, Integer size, Long labId, String status, String keyword) {
        Page<Device> page = new Page<>(current, size);
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Device::getId);

        if (labId != null) {
            wrapper.eq(Device::getLabId, labId);
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(Device::getStatus, status);
        }
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(Device::getName, keyword)
                    .or().like(Device::getModel, keyword)
                    .or().like(Device::getSerialNumber, keyword));
        }

        return deviceMapper.selectPage(page, wrapper);
    }

    /**
     * 获取详情
     */
    public Device getById(Long id) {
        return deviceMapper.selectById(id);
    }

    /**
     * 新增
     */
    @Transactional
    public void create(Device device, Long operatorId) {
        device.setCreateTime(LocalDateTime.now());
        device.setStatus("NORMAL");
        deviceMapper.insert(device);
        operationLogService.log(operatorId, "CREATE", "DEVICE", "新增设备: " + device.getName(), null);
    }

    /**
     * 更新
     */
    @Transactional
    public void update(Long id, Device device, Long operatorId) {
        device.setId(id);
        device.setUpdateTime(LocalDateTime.now());
        deviceMapper.updateById(device);
        operationLogService.log(operatorId, "UPDATE", "DEVICE", "更新设备: " + id, null);
    }

    /**
     * 删除
     */
    @Transactional
    public void delete(Long id, Long operatorId) {
        deviceMapper.deleteById(id);
        operationLogService.log(operatorId, "DELETE", "DEVICE", "删除设备: " + id, null);
    }

    /**
     * 借用设备
     */
    @Transactional
    public void borrow(Long id, BorrowRequest request, Long borrowerId) {
        Device device = deviceMapper.selectById(id);
        if (device == null) {
            throw new BusinessException(404, "设备不存在");
        }
        if (!"NORMAL".equals(device.getStatus())) {
            throw new BusinessException(ResultCode.DEVICE_NOT_AVAILABLE);
        }

        device.setStatus("BORROWED");
        device.setBorrowerId(borrowerId);
        device.setBorrowTime(LocalDateTime.now());
        device.setExpectReturnTime(request.getExpectReturnTime());
        deviceMapper.updateById(device);

        operationLogService.log(borrowerId, "BORROW", "DEVICE", "借用设备: " + id, null);
    }

    /**
     * 归还设备
     */
    @Transactional
    public void returnDevice(Long id, Long operatorId) {
        Device device = deviceMapper.selectById(id);
        if (device == null) {
            throw new BusinessException(404, "设备不存在");
        }
        if (!"BORROWED".equals(device.getStatus())) {
            throw new BusinessException(400, "设备当前不在借用中");
        }

        device.setStatus("NORMAL");
        device.setReturnTime(LocalDateTime.now());
        device.setBorrowerId(null);
        deviceMapper.updateById(device);

        operationLogService.log(operatorId, "RETURN", "DEVICE", "归还设备: " + id, null);
    }
}
