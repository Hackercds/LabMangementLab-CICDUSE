package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.result.Result;
import com.labmanagement.entity.Consumable;
import com.labmanagement.entity.ConsumableLog;
import com.labmanagement.service.ConsumableService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestAttribute;

import java.util.List;

/**
 * 耗材管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/consumable")
@RequiredArgsConstructor
public class ConsumableController {

    private final ConsumableService consumableService;

    /**
     * 获取全部耗材列表
     */
    @GetMapping("/list")
    public Result<List<Consumable>> listAll() {
        List<Consumable> list = consumableService.listAll();
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/page")
    public Result<IPage<Consumable>> page(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) String keyword) {
        IPage<Consumable> page = consumableService.pageList(current, size, keyword);
        return Result.success(page);
    }

    /**
     * 获取低库存耗材列表
     */
    @GetMapping("/warning")
    public Result<List<Consumable>> warningList() {
        List<Consumable> list = consumableService.getLowStockList();
        return Result.success(list);
    }

    /**
     * 获取耗材出入库记录
     */
    @GetMapping("/{id}/logs")
    public Result<IPage<ConsumableLog>> logs(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size) {
        IPage<ConsumableLog> page = consumableService.getLogs(id, current, size);
        return Result.success(page);
    }

    /**
     * 获取详情
     */
    @GetMapping("/{id}")
    public Result<Consumable> getById(@PathVariable Long id) {
        Consumable consumable = consumableService.getById(id);
        return Result.success(consumable);
    }

    /**
     * 新增
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> create(@RequestBody Consumable consumable, @RequestAttribute Long userId) {
        consumableService.create(consumable, userId);
        return Result.success();
    }

    /**
     * 更新
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> update(@PathVariable Long id, @RequestBody Consumable consumable, @RequestAttribute Long userId) {
        consumableService.update(id, consumable, userId);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> delete(@PathVariable Long id, @RequestAttribute Long userId) {
        consumableService.delete(id, userId);
        return Result.success();
    }

    /**
     * 入库
     */
    @PostMapping("/{id}/in")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> in(
            @PathVariable Long id,
            @RequestBody ConsumableService.InRequest request,
            @RequestAttribute Long userId) {
        consumableService.in(id, request, userId);
        return Result.success();
    }

    /**
     * 领用出库
     */
    @PostMapping("/{id}/out")
    public Result<Boolean> out(
            @PathVariable Long id,
            @RequestBody ConsumableService.UseRequest request,
            @RequestAttribute Long userId) {
        boolean needWarning = consumableService.out(id, request, userId);
        return Result.success(needWarning);
    }
}
