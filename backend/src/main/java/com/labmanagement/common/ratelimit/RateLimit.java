package com.labmanagement.common.ratelimit;

import java.lang.annotation.*;

/**
 * 限流注解
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RateLimit {
    
    /**
     * 限流Key
     */
    String key() default "";
    
    /**
     * 限流次数
     */
    int limit() default 10;
    
    /**
     * 限流时间窗口（秒）
     */
    int timeout() default 1;
}
