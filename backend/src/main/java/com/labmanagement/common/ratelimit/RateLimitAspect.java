package com.labmanagement.common.ratelimit;

import com.labmanagement.config.AppProperties;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * 限流切面 — 通过 app.security.rate-limit.enabled 控制开关
 */
@Slf4j
@Aspect
@Component
public class RateLimitAspect {

    @Autowired
    private StringRedisTemplate redisTemplate;

    @Autowired
    private AppProperties appProperties;

    /**
     * 限流切面
     */
    @Around("@annotation(rateLimit)")
    public Object around(ProceedingJoinPoint point, RateLimit rateLimit) throws Throwable {
        // 配置关闭时限流不生效
        AppProperties.RateLimitProperties rlConfig = appProperties.getSecurity() != null
                ? appProperties.getSecurity().getRateLimit() : null;
        if (rlConfig == null || rlConfig.getEnabled() == null || !rlConfig.getEnabled()) {
            return point.proceed();
        }

        String key = buildKey(point, rateLimit);
        int limit = rateLimit.limit();
        int timeout = rateLimit.timeout();

        try {
            Long count = redisTemplate.opsForValue().increment(key);

            if (count != null && count == 1) {
                redisTemplate.expire(key, timeout, TimeUnit.SECONDS);
            }

            if (count != null && count > limit) {
                log.warn("请求频率超限: key={}, limit={}, current={}", key, limit, count);
                throw new RuntimeException("请求频率超限，请稍后重试");
            }

            log.debug("限流检查通过: key={}, count={}", key, count);
            return point.proceed();
        } catch (Exception e) {
            log.error("限流检查失败: {}", e.getMessage());
            throw e;
        }
    }

    /**
     * 构建限流Key
     */
    private String buildKey(ProceedingJoinPoint point, RateLimit rateLimit) {
        String className = point.getTarget().getClass().getSimpleName();
        String methodName = point.getSignature().getName();
        String key = rateLimit.key();
        
        if (key.isEmpty()) {
            key = String.format("rate_limit:%s:%s", className, methodName);
        }
        
        return key;
    }
}
