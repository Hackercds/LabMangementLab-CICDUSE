package com.labmanagement.common.util;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 客户端真实IP获取工具
 * 优先读取 nginx 代理头 X-Real-IP / X-Forwarded-For
 */
public final class IPUtils {

    public static String getClientIP(HttpServletRequest request) {
        // nginx X-Real-IP
        String ip = request.getHeader("X-Real-IP");
        if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip)) {
            return ip;
        }

        // X-Forwarded-For 第一个IP
        ip = request.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip)) {
            return ip.split(",")[0].trim();
        }

        // fallback
        return request.getRemoteAddr();
    }
}
