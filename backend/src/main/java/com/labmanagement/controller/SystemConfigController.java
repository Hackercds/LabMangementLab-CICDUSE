package com.labmanagement.controller;

import com.labmanagement.common.result.Result;
import com.labmanagement.service.SystemConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/system-config")
@RequiredArgsConstructor
public class SystemConfigController {
    
    private final SystemConfigService systemConfigService;
    
    /**
     * 获取所有配置
     */
    @GetMapping("/list")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<List<Map<String, String>>> listConfigs() {
        List<Map<String, String>> configs = List.of(
            Map.of(
                "key", "auto_approve_teacher",
                "value", systemConfigService.getConfig("auto_approve_teacher"),
                "description", "教师审批预约时是否自动审批无冲突预约"
            )
        );
        return Result.success(configs);
    }
    
    /**
     * 更新配置
     */
    @PutMapping("/update")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> updateConfig(@RequestParam String key, @RequestParam String value) {
        systemConfigService.updateConfig(key, value);
        return Result.success();
    }
    
    /**
     * 获取自动审批开关状态
     */
    @GetMapping("/auto-approve")
    public Result<Boolean> getAutoApprove() {
        boolean enabled = systemConfigService.getBooleanConfig("auto_approve_teacher", false);
        return Result.success(enabled);
    }
}
