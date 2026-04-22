package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.common.result.ResultCode;
import com.labmanagement.entity.Consumable;
import com.labmanagement.entity.ConsumableLog;
import com.labmanagement.mapper.ConsumableLogMapper;
import com.labmanagement.mapper.ConsumableMapper;
import lombok.RequiredArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 耗材管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ConsumableService {

    private final ConsumableMapper consumableMapper;
    private final ConsumableLogMapper consumableLogMapper;
    private final OperationLogService operationLogService;

    @lombok.Data
    public static class UseRequest {
        private Long consumableId;
        private BigDecimal quantity;
        private String receiver;
        private String purpose;
    }

    @lombok.Data
    public static class InRequest {
        private Long consumableId;
        private BigDecimal quantity;
        private String receiver;
        private String purpose;
    }

    /**
     * 获取全部耗材列表
     */
    public List<Consumable> listAll() {
        LambdaQueryWrapper<Consumable> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Consumable::getId);
        return consumableMapper.selectList(wrapper);
    }

    /**
     * 分页查询
     */
    public IPage<Consumable> pageList(Integer current, Integer size, String keyword) {
        Page<Consumable> page = new Page<>(current, size);
        LambdaQueryWrapper<Consumable> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByAsc(Consumable::getId);

        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(Consumable::getName, keyword)
                    .or().like(Consumable::getSpecification, keyword));
        }

        return consumableMapper.selectPage(page, wrapper);
    }

    /**
     * 获取低库存耗材列表
     */
    public List<Consumable> getLowStockList() {
        return consumableMapper.selectLowStockList();
    }

    /**
     * 获取出入库记录
     */
    public IPage<ConsumableLog> getLogs(Long id, Integer current, Integer size) {
        Page<ConsumableLog> page = new Page<>(current, size);
        LambdaQueryWrapper<ConsumableLog> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ConsumableLog::getConsumableId, id)
                .orderByDesc(ConsumableLog::getOperationTime);
        return consumableLogMapper.selectPage(page, wrapper);
    }

    /**
     * 获取详情
     */
    public Consumable getById(Long id) {
        return consumableMapper.selectById(id);
    }

    /**
     * 新增
     */
    @Transactional
    public void create(Consumable consumable, Long operatorId) {
        if (consumable.getCurrentStock() == null) {
            consumable.setCurrentStock(BigDecimal.ZERO);
        }
        consumable.setCreateTime(LocalDateTime.now());
        consumableMapper.insert(consumable);
        operationLogService.log(operatorId, "CREATE", "CONSUMABLE", "新增耗材: " + consumable.getName(), null);
    }

    /**
     * 更新
     */
    @Transactional
    public void update(Long id, Consumable consumable, Long operatorId) {
        consumable.setId(id);
        consumable.setUpdateTime(LocalDateTime.now());
        consumableMapper.updateById(consumable);
        operationLogService.log(operatorId, "UPDATE", "CONSUMABLE", "更新耗材: " + id, null);
    }

    /**
     * 删除
     */
    @Transactional
    public void delete(Long id, Long operatorId) {
        consumableMapper.deleteById(id);
        operationLogService.log(operatorId, "DELETE", "CONSUMABLE", "删除耗材: " + id, null);
    }

    /**
     * 入库
     */
    @Transactional
    public void in(Long id, InRequest request, Long operatorId) {
        Consumable consumable = consumableMapper.selectById(id);
        if (consumable == null) {
            throw new BusinessException(404, "耗材不存在");
        }

        // 更新库存
        BigDecimal newStock = consumable.getCurrentStock().add(request.getQuantity());
        consumable.setCurrentStock(newStock);
        consumableMapper.updateById(consumable);

        // 记录日志
        ConsumableLog log = new ConsumableLog();
        log.setConsumableId(id);
        log.setOperationType("IN");
        log.setQuantity(request.getQuantity());
        log.setOperatorId(operatorId);
        log.setOperationTime(LocalDateTime.now());
        log.setReceiver(request.getReceiver());
        log.setPurpose(request.getPurpose());
        consumableLogMapper.insert(log);

        operationLogService.log(operatorId, "IN", "CONSUMABLE",
                "耗材入库: " + id + ", 数量: " + request.getQuantity(), null);
    }

    /**
     * 领用出库
     */
    @Transactional
    public boolean out(Long id, UseRequest request, Long operatorId) {
        Consumable consumable = consumableMapper.selectById(id);
        if (consumable == null) {
            throw new BusinessException(404, "耗材不存在");
        }

        // 检查库存
        if (consumable.getCurrentStock().compareTo(request.getQuantity()) < 0) {
            throw new BusinessException(ResultCode.INSUFFICIENT_STOCK);
        }

        // 更新库存
        BigDecimal newStock = consumable.getCurrentStock().subtract(request.getQuantity());
        consumable.setCurrentStock(newStock);
        consumableMapper.updateById(consumable);

        // 记录日志
        ConsumableLog log = new ConsumableLog();
        log.setConsumableId(id);
        log.setOperationType("OUT");
        log.setQuantity(request.getQuantity());
        log.setOperatorId(operatorId);
        log.setOperationTime(LocalDateTime.now());
        log.setReceiver(request.getReceiver() != null ? request.getReceiver() : "");
        log.setPurpose(request.getPurpose());
        consumableLogMapper.insert(log);

        operationLogService.log(operatorId, "OUT", "CONSUMABLE",
                "耗材领用: " + id + ", 数量: " + request.getQuantity(), null);

        // 检查是否需要预警
        boolean needWarning = false;
        if (consumable.getWarningThreshold() != null &&
                consumable.getWarningThreshold().compareTo(BigDecimal.ZERO) > 0 &&
                newStock.compareTo(consumable.getWarningThreshold()) <= 0) {
            needWarning = true;
            operationLogService.log(operatorId, "WARNING", "CONSUMABLE",
                    "耗材库存低于预警阈值: " + consumable.getName() +
                            ", 当前库存: " + newStock + ", 阈值: " + consumable.getWarningThreshold(), null);
        }

        return needWarning;
    }
}
