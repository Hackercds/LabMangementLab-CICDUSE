package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.result.Result;
import com.labmanagement.entity.Device;
import com.labmanagement.service.DeviceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestAttribute;

import java.util.List;

/**
 * 设备管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/device")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceService deviceService;

    /**
     * 条件查询列表
     */
    @GetMapping("/list")
    public Result<List<Device>> list(
            @RequestParam(required = false) Long labId,
            @RequestParam(required = false) String status) {
        List<Device> list = deviceService.list(labId, status);
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/page")
    public Result<IPage<Device>> page(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) Long labId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {
        IPage<Device> page = deviceService.pageList(current, size, labId, status, keyword);
        return Result.success(page);
    }

    /**
     * 获取详情
     */
    @GetMapping("/{id}")
    public Result<Device> getById(@PathVariable Long id) {
        Device device = deviceService.getById(id);
        return Result.success(device);
    }

    /**
     * 新增
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> create(@RequestBody Device device, @RequestAttribute Long userId) {
        deviceService.create(device, userId);
        return Result.success();
    }

    /**
     * 更新
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> update(@PathVariable Long id, @RequestBody Device device, @RequestAttribute Long userId) {
        deviceService.update(id, device, userId);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> delete(@PathVariable Long id, @RequestAttribute Long userId) {
        deviceService.delete(id, userId);
        return Result.success();
    }

    /**
     * 借用设备
     */
    @PostMapping("/{id}/borrow")
    public Result<Void> borrow(
            @PathVariable Long id,
            @RequestBody DeviceService.BorrowRequest request,
            @RequestAttribute Long userId) {
        deviceService.borrow(id, request, userId);
        return Result.success();
    }

    /**
     * 归还设备
     */
    @PostMapping("/{id}/return")
    public Result<Void> returnDevice(@PathVariable Long id, @RequestAttribute Long userId) {
        deviceService.returnDevice(id, userId);
        return Result.success();
    }
}
