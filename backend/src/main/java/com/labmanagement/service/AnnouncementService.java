package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.entity.Announcement;
import com.labmanagement.mapper.AnnouncementMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 公告服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AnnouncementService {

    private final AnnouncementMapper announcementMapper;
    private final OperationLogService operationLogService;

    /**
     * 前台分页查询已发布公告
     */
    public IPage<Announcement> publicPageList(Integer current, Integer size) {
        Page<Announcement> page = new Page<>(current, size);
        LambdaQueryWrapper<Announcement> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Announcement::getStatus, "PUBLISHED")
                .orderByDesc(Announcement::getIsTop)
                .orderByDesc(Announcement::getPublishTime);
        return announcementMapper.selectPage(page, wrapper);
    }

    /**
     * 管理端分页查询
     */
    public IPage<Announcement> adminPageList(Integer current, Integer size, String status, String keyword) {
        Page<Announcement> page = new Page<>(current, size);
        LambdaQueryWrapper<Announcement> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(Announcement::getIsTop)
                .orderByDesc(Announcement::getPublishTime);

        if (StringUtils.hasText(status)) {
            wrapper.eq(Announcement::getStatus, status);
        }
        if (StringUtils.hasText(keyword)) {
            wrapper.like(Announcement::getTitle, keyword);
        }

        return announcementMapper.selectPage(page, wrapper);
    }

    /**
     * 获取详情
     */
    public Announcement getById(Long id) {
        return announcementMapper.selectById(id);
    }

    /**
     * 新增
     */
    @Transactional
    public void create(Announcement announcement, Long publisherId) {
        announcement.setPublisherId(publisherId);
        announcement.setPublishTime(LocalDateTime.now());
        announcement.setCreateTime(LocalDateTime.now());
        if (!StringUtils.hasText(announcement.getStatus())) {
            announcement.setStatus("PUBLISHED");
        }
        if (announcement.getIsTop() == null) {
            announcement.setIsTop(false);
        }
        announcementMapper.insert(announcement);
        operationLogService.log(publisherId, "CREATE", "ANNOUNCEMENT", "新增公告: " + announcement.getTitle(), null);
    }

    /**
     * 更新
     */
    @Transactional
    public void update(Long id, Announcement announcement, Long operatorId) {
        announcement.setId(id);
        announcement.setUpdateTime(LocalDateTime.now());
        announcementMapper.updateById(announcement);
        operationLogService.log(operatorId, "UPDATE", "ANNOUNCEMENT", "更新公告: " + id, null);
    }

    /**
     * 删除
     */
    @Transactional
    public void delete(Long id, Long operatorId) {
        announcementMapper.deleteById(id);
        operationLogService.log(operatorId, "DELETE", "ANNOUNCEMENT", "删除公告: " + id, null);
    }
}
