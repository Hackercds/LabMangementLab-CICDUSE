package com.labmanagement.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.labmanagement.common.result.Result;
import com.labmanagement.entity.Announcement;
import com.labmanagement.service.AnnouncementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestAttribute;

/**
 * 公告控制器
 */
@Slf4j
@RestController
@RequestMapping("/announcement")
@RequiredArgsConstructor
public class AnnouncementController {

    private final AnnouncementService announcementService;

    /**
     * 前台公开获取已发布公告列表
     */
    @GetMapping("/list")
    public Result<IPage<Announcement>> publicList(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size) {
        IPage<Announcement> page = announcementService.publicPageList(current, size);
        return Result.success(page);
    }

    /**
     * 获取公告详情（公开访问
     */
    @GetMapping("/{id}")
    public Result<Announcement> getById(@PathVariable Long id) {
        Announcement announcement = announcementService.getById(id);
        return Result.success(announcement);
    }

    /**
     * 管理端分页查询
     */
    @GetMapping("/admin/page")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<IPage<Announcement>> adminPage(
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {
        IPage<Announcement> page = announcementService.adminPageList(current, size, status, keyword);
        return Result.success(page);
    }

    /**
     * 新增公告
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> create(@RequestBody Announcement announcement, @RequestAttribute Long userId) {
        announcementService.create(announcement, userId);
        return Result.success();
    }

    /**
     * 更新公告
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> update(@PathVariable Long id, @RequestBody Announcement announcement, @RequestAttribute Long userId) {
        announcementService.update(id, announcement, userId);
        return Result.success();
    }

    /**
     * 删除公告
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> delete(@PathVariable Long id, @RequestAttribute Long userId) {
        announcementService.delete(id, userId);
        return Result.success();
    }
}
