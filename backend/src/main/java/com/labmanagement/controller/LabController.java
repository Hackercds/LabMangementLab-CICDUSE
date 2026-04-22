package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.result.Result;
import com.labmanagement.entity.Lab;
import com.labmanagement.service.LabService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestAttribute;

import java.util.List;

/**
 * 实验室控制器
 */
@Slf4j
@RestController
@RequestMapping("/lab")
@RequiredArgsConstructor
public class LabController {

    private final LabService labService;

    /**
     * 获取全部实验室列表（供下拉选择
     */
    @GetMapping("/list")
    public Result<List<Lab>> listAll() {
        List<Lab> list = labService.listAll();
        return Result.success(list);
    }

    /**
     * 分页查询
     */
    @GetMapping("/page")
    public Result<IPage<Lab>> page(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status) {
        IPage<Lab> page = labService.pageList(current, size, keyword, status);
        return Result.success(page);
    }

    /**
     * 获取详情
     */
    @GetMapping("/{id}")
    public Result<Lab> getById(@PathVariable Long id) {
        Lab lab = labService.getById(id);
        return Result.success(lab);
    }

    /**
     * 新增
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> create(@RequestBody Lab lab, @RequestAttribute Long userId) {
        labService.create(lab, userId);
        return Result.success();
    }

    /**
     * 更新
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> update(@PathVariable Long id, @RequestBody Lab lab, @RequestAttribute Long userId) {
        labService.update(id, lab, userId);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> delete(@PathVariable Long id, @RequestAttribute Long userId) {
        labService.delete(id, userId);
        return Result.success();
    }
}
