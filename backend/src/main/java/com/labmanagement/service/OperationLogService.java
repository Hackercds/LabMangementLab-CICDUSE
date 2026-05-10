package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.util.IPUtils;
import com.labmanagement.entity.OperationLog;
import com.labmanagement.mapper.OperationLogMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;

/**
 * 操作日志服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OperationLogService {

    private final OperationLogMapper operationLogMapper;

    private String resolveIP(String ipAddress) {
        if (ipAddress != null && !ipAddress.isEmpty()) return ipAddress;
        try {
            ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs != null) {
                HttpServletRequest req = attrs.getRequest();
                return IPUtils.getClientIP(req);
            }
        } catch (Exception ignored) {}
        return null;
    }

    public void log(Long operatorId, String operationType, String module, String description, String ipAddress) {
        OperationLog log = new OperationLog();
        log.setOperatorId(operatorId); log.setOperationType(operationType);
        log.setModule(module); log.setDescription(description);
        log.setIpAddress(resolveIP(ipAddress));
        log.setOperationTime(LocalDateTime.now()); log.setCreateTime(LocalDateTime.now());
        operationLogMapper.insert(log);
    }

    public void logWithSnapshot(Long operatorId, String operationType, String module,
                                 String description, String ipAddress,
                                 String beforeSnapshot, String afterSnapshot) {
        OperationLog log = new OperationLog();
        log.setOperatorId(operatorId); log.setOperationType(operationType);
        log.setModule(module); log.setDescription(description);
        log.setIpAddress(resolveIP(ipAddress));
        log.setBeforeSnapshot(beforeSnapshot); log.setAfterSnapshot(afterSnapshot);
        log.setOperationTime(LocalDateTime.now()); log.setCreateTime(LocalDateTime.now());
        operationLogMapper.insert(log);
    }

    /**
     * 分页查询日志
     */
    public IPage<OperationLog> pageList(Integer current, Integer size, Long operatorId, String module, String operationType) {
        Page<OperationLog> page = new Page<>(current, size);
        LambdaQueryWrapper<OperationLog> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(OperationLog::getOperationTime);

        if (operatorId != null) {
            wrapper.eq(OperationLog::getOperatorId, operatorId);
        }
        if (StringUtils.hasText(module)) {
            wrapper.eq(OperationLog::getModule, module);
        }
        if (StringUtils.hasText(operationType)) {
            wrapper.eq(OperationLog::getOperationType, operationType);
        }

        return operationLogMapper.selectPage(page, wrapper);
    }
}
