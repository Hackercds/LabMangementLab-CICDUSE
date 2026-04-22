package com.labmanagement.common.cache;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * 缓存组件
 */
@Slf4j
@Component
public class CacheComponent {

    @Autowired
    private StringRedisTemplate redisTemplate;

    /**
     * 设置缓存
     */
    public void set(String key, String value, long timeout, TimeUnit unit) {
        try {
            redisTemplate.opsForValue().set(key, value, timeout, unit);
            log.debug("设置缓存成功: key={}, timeout={}{}", key, timeout, unit);
        } catch (Exception e) {
            log.error("设置缓存失败: key={}, error={}", key, e.getMessage());
        }
    }

    /**
     * 获取缓存
     */
    public String get(String key) {
        try {
            String value = redisTemplate.opsForValue().get(key);
            log.debug("获取缓存: key={}, exists={}", key, value != null);
            return value;
        } catch (Exception e) {
            log.error("获取缓存失败: key={}, error={}", key, e.getMessage());
            return null;
        }
    }

    /**
     * 删除缓存
     */
    public void delete(String key) {
        try {
            redisTemplate.delete(key);
            log.debug("删除缓存成功: key={}", key);
        } catch (Exception e) {
            log.error("删除缓存失败: key={}, error={}", key, e.getMessage());
        }
    }

    /**
     * 判断缓存是否存在
     */
    public boolean exists(String key) {
        try {
            Boolean exists = redisTemplate.hasKey(key);
            return exists != null && exists;
        } catch (Exception e) {
            log.error("判断缓存是否存在失败: key={}, error={}", key, e.getMessage());
            return false;
        }
    }

    /**
     * 设置过期时间
     */
    public void expire(String key, long timeout, TimeUnit unit) {
        try {
            redisTemplate.expire(key, timeout, unit);
            log.debug("设置过期时间成功: key={}, timeout={}{}", key, timeout, unit);
        } catch (Exception e) {
            log.error("设置过期时间失败: key={}, error={}", key, e.getMessage());
        }
    }

    /**
     * 获取剩余过期时间
     */
    public long getExpire(String key, TimeUnit unit) {
        try {
            Long expire = redisTemplate.getExpire(key, unit);
            return expire != null ? expire : -2;
        } catch (Exception e) {
            log.error("获取剩余过期时间失败: key={}, error={}", key, e.getMessage());
            return -2;
        }
    }

    /**
     * 自增
     */
    public long increment(String key) {
        try {
            Long value = redisTemplate.opsForValue().increment(key);
            return value != null ? value : 0;
        } catch (Exception e) {
            log.error("自增失败: key={}, error={}", key, e.getMessage());
            return 0;
        }
    }

    /**
     * 自增指定值
     */
    public long increment(String key, long delta) {
        try {
            Long value = redisTemplate.opsForValue().increment(key, delta);
            return value != null ? value : 0;
        } catch (Exception e) {
            log.error("自增失败: key={}, delta={}, error={}", key, delta, e.getMessage());
            return 0;
        }
    }

    /**
     * 自减
     */
    public long decrement(String key) {
        try {
            Long value = redisTemplate.opsForValue().decrement(key);
            return value != null ? value : 0;
        } catch (Exception e) {
            log.error("自减失败: key={}, error={}", key, e.getMessage());
            return 0;
        }
    }
}
