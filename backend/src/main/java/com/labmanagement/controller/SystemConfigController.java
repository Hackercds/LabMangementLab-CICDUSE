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
        return Result.success(List.of(
            Map.of("key","auto_approve_teacher","value",systemConfigService.getConfig("auto_approve_teacher"),"description","教师自动审批"),
            Map.of("key","admin_time_override","value",systemConfigService.getConfig("admin_time_override"),"description","管理员时间覆盖(YYYY-MM-DD,空=当前时间)")
        ));
    }

    /** 设置管理员时间覆盖 */
    @PutMapping("/admin-time")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> setAdminTime(@RequestParam(required = false) String date) {
        systemConfigService.updateConfig("admin_time_override", date != null ? date : "");
        return Result.success();
    }

    /** 获取当前有效时间 */
    @GetMapping("/current-time")
    public Result<String> getCurrentTime() {
        String override = systemConfigService.getConfig("admin_time_override");
        return Result.success(override != null && !override.isEmpty() ? override : java.time.LocalDate.now().toString());
    }

    /** 获取服务器时间戳（用于客户端时间校验） */
    @GetMapping("/server-time")
    public Result<Long> getServerTime() {
        return Result.success(System.currentTimeMillis());
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
