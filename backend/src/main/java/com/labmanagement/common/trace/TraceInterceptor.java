package com.labmanagement.common.trace;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.UUID;

/**
 * 日志追踪拦截器
 */
@Slf4j
@Component
public class TraceInterceptor implements HandlerInterceptor {

    private static final String TRACE_ID = "traceId";
    private static final String USER_ID = "userId";
    private static final String REQUEST_ID = "requestId";

    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String traceId = request.getHeader("X-Trace-Id");
        if (traceId == null || traceId.isEmpty()) {
            traceId = UUID.randomUUID().toString().replace("-", "");
        }
        
        MDC.put(TRACE_ID, traceId);
        MDC.put(REQUEST_ID, UUID.randomUUID().toString().replace("-", ""));
        
        response.setHeader("X-Trace-Id", traceId);
        
        log.debug("请求开始: method={}, uri={}, traceId={}", 
                request.getMethod(), request.getRequestURI(), traceId);
        
        return true;
    }

    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        log.debug("请求结束: method={}, uri={}, status={}", 
                request.getMethod(), request.getRequestURI(), response.getStatus());
        
        MDC.remove(TRACE_ID);
        MDC.remove(USER_ID);
        MDC.remove(REQUEST_ID);
    }

    /**
     * 设置用户ID
     */
    public static void setUserId(String userId) {
        MDC.put(USER_ID, userId);
    }

    /**
     * 获取追踪ID
     */
    public static String getTraceId() {
        return MDC.get(TRACE_ID);
    }

    /**
     * 获取用户ID
     */
    public static String getUserId() {
        return MDC.get(USER_ID);
    }

    /**
     * 获取请求ID
     */
    public static String getRequestId() {
        return MDC.get(REQUEST_ID);
    }
}
