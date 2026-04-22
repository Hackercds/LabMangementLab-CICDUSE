package com.labmanagement.service;

import com.labmanagement.entity.Consumable;
import com.labmanagement.entity.ConsumableLog;
import com.labmanagement.mapper.ConsumableMapper;
import com.labmanagement.mapper.ConsumableLogMapper;
import com.labmanagement.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * 耗材领用单元测试
 */
@ExtendWith(MockitoExtension.class)
public class ConsumableServiceTest {

    @Mock
    private ConsumableMapper consumableMapper;

    @Mock
    private ConsumableLogMapper consumableLogMapper;

    @Mock
    private OperationLogService operationLogService;

    @InjectMocks
    private ConsumableService consumableService;

    /**
     * 测试用例1: 领用后库存高于阈值，不预警
     * 当前库存: 100，领用: 20，阈值: 10 → 剩余: 80 ≥ 10
     * 预期结果: 领用成功，不需要预警
     */
    @Test
    public void testConsumeOk_NoWarning() {
        // Given
        Long id = 1L;
        Consumable consumable = new Consumable();
        consumable.setId(id);
        consumable.setName("测试耗材");
        consumable.setCurrentStock(new BigDecimal("100"));
        consumable.setWarningThreshold(new BigDecimal("10"));

        ConsumableService.UseRequest request = new ConsumableService.UseRequest();
        request.setQuantity(new BigDecimal("20"));

        when(consumableMapper.selectById(id)).thenReturn(consumable);

        // When
        boolean needWarning = consumableService.out(id, request, 1L);

        // Then
        assertFalse(needWarning);
        // 验证库存扣减正确
        assertEquals(new BigDecimal("80"), consumable.getCurrentStock());
        verify(consumableMapper, times(1)).updateById(any());
        verify(consumableLogMapper, times(1)).insert(any());
    }

    /**
     * 测试用例2: 领用后库存低于阈值，需要预警
     * 当前库存: 15，领用: 10，阈值: 10 → 剩余: 5 < 10
     * 预期结果: 领用成功，需要预警
     */
    @Test
    public void testConsumeOk_NeedWarning() {
        // Given
        Long id = 1L;
        Consumable consumable = new Consumable();
        consumable.setId(id);
        consumable.setName("测试耗材");
        consumable.setCurrentStock(new BigDecimal("15"));
        consumable.setWarningThreshold(new BigDecimal("10"));

        ConsumableService.UseRequest request = new ConsumableService.UseRequest();
        request.setQuantity(new BigDecimal("10"));

        when(consumableMapper.selectById(id)).thenReturn(consumable);

        // When
        boolean needWarning = consumableService.out(id, request, 1L);

        // Then
        assertTrue(needWarning);
        assertEquals(new BigDecimal("5"), consumable.getCurrentStock());
        verify(consumableMapper, times(1)).updateById(any());
        verify(consumableLogMapper, times(1)).insert(any());
    }

    /**
     * 测试用例3: 库存不足，领用失败
     * 当前库存: 5，领用: 10 → 5 < 10
     * 预期结果: 抛出异常，领用失败
     */
    @Test
    public void testConsumeFail_insufficientStock() {
        // Given
        Long id = 1L;
        Consumable consumable = new Consumable();
        consumable.setId(id);
        consumable.setName("测试耗材");
        consumable.setCurrentStock(new BigDecimal("5"));
        consumable.setWarningThreshold(new BigDecimal("10"));

        ConsumableService.UseRequest request = new ConsumableService.UseRequest();
        request.setQuantity(new BigDecimal("10"));

        when(consumableMapper.selectById(id)).thenReturn(consumable);

        // When & Then
        assertThrows(BusinessException.class, () -> {
            consumableService.out(id, request, 1L);
        });

        verify(consumableMapper, never()).updateById(any());
        verify(consumableLogMapper, never()).insert(any());
    }

    /**
     * 测试用例4: 领用后库存刚好等于阈值，需要预警
     * 当前库存: 10，领用: 0，阈值: 10 → 剩余: 10 = 10
     * 预期结果: 需要预警
     */
    @Test
    public void testConsume_equalsThreshold() {
        // Given
        Long id = 1L;
        Consumable consumable = new Consumable();
        consumable.setId(id);
        consumable.setName("测试耗材");
        consumable.setCurrentStock(new BigDecimal("10"));
        consumable.setWarningThreshold(new BigDecimal("10"));

        ConsumableService.UseRequest request = new ConsumableService.UseRequest();
        request.setQuantity(new BigDecimal("0"));

        when(consumableMapper.selectById(id)).thenReturn(consumable);

        // When
        boolean needWarning = consumableService.out(id, request, 1L);

        // Then
        assertTrue(needWarning);
    }
}
