package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.entity.Lab;
import com.labmanagement.mapper.LabMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 实验室管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LabService {

    private final LabMapper labMapper;
    private final OperationLogService operationLogService;

    /**
     * 获取全部实验室列表
     */
    public List<Lab> listAll() {
        LambdaQueryWrapper<Lab> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Lab::getId);
        return labMapper.selectList(wrapper);
    }

    /**
     * 分页查询
     */
    public IPage<Lab> pageList(Integer current, Integer size, String keyword, String status) {
        Page<Lab> page = new Page<>(current, size);
        LambdaQueryWrapper<Lab> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Lab::getId);

        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(Lab::getName, keyword).or().like(Lab::getLocation, keyword));
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(Lab::getStatus, status);
        }

        return labMapper.selectPage(page, wrapper);
    }

    /**
     * 获取详情
     */
    public Lab getById(Long id) {
        return labMapper.selectById(id);
    }

    /**
     * 新增
     */
    @Transactional
    public void create(Lab lab, Long operatorId) {
        lab.setCreateTime(LocalDateTime.now());
        labMapper.insert(lab);
        operationLogService.log(operatorId, "CREATE", "LAB", "新增实验室: " + lab.getName(), null);
    }

    /**
     * 更新
     */
    @Transactional
    public void update(Long id, Lab lab, Long operatorId) {
        lab.setId(id);
        lab.setUpdateTime(LocalDateTime.now());
        labMapper.updateById(lab);
        operationLogService.log(operatorId, "UPDATE", "LAB", "更新实验室: " + id, null);
    }

    /**
     * 删除
     */
    @Transactional
    public void delete(Long id, Long operatorId) {
        labMapper.deleteById(id);
        operationLogService.log(operatorId, "DELETE", "LAB", "删除实验室: " + id, null);
    }
}
