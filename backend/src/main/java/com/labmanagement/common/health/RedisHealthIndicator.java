package com.labmanagement.common.health;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisConnectionUtils;
import org.springframework.stereotype.Component;

/**
 * Redis健康检查
 */
@Slf4j
@Component
public class RedisHealthIndicator implements HealthIndicator {

    @Autowired
    private RedisConnectionFactory redisConnectionFactory;

    @Override
    public Health health() {
        try {
            var connection = RedisConnectionUtils.getConnection(redisConnectionFactory);
            try {
                String pong = connection.ping();
                if ("PONG".equalsIgnoreCase(pong)) {
                    return Health.up()
                            .withDetail("redis", "Connected")
                            .withDetail("response", pong)
                            .build();
                } else {
                    return Health.down()
                            .withDetail("error", "Redis响应异常: " + pong)
                            .build();
                }
            } finally {
                RedisConnectionUtils.releaseConnection(connection, redisConnectionFactory);
            }
        } catch (Exception e) {
            log.error("Redis健康检查失败: {}", e.getMessage());
            return Health.down()
                    .withDetail("error", e.getMessage())
                    .build();
        }
    }
}
