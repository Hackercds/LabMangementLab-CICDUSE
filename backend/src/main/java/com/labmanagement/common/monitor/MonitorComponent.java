package com.labmanagement.common.monitor;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Gauge;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * 监控告警组件 — Redis 存储 + Micrometer 暴露给 Prometheus
 */
@Slf4j
@Component
public class MonitorComponent {

    @Autowired
    private StringRedisTemplate redisTemplate;

    private final AtomicLong memoryUsage = new AtomicLong(0);
    private final AtomicInteger threadCount = new AtomicInteger(0);

    public MonitorComponent(MeterRegistry registry) {
        Gauge.builder("app.memory.usage.percent", memoryUsage, AtomicLong::get)
                .description("JVM 内存使用率(%)")
                .register(registry);
        Gauge.builder("app.thread.count", threadCount, AtomicInteger::get)
                .description("活跃线程数")
                .register(registry);
    }

    private static final String METRICS_PREFIX = "metrics:";
    private static final String ALERT_PREFIX = "alert:";

    /**
     * 记录指标
     */
    public void recordMetric(String name, double value) {
        String key = METRICS_PREFIX + name;
        try {
            redisTemplate.opsForValue().set(key, String.valueOf(value), 1, TimeUnit.HOURS);
            log.debug("记录指标: {}={}", name, value);
        } catch (Exception e) {
            log.error("记录指标失败: {}", e.getMessage());
        }
    }

    /**
     * 增加计数器
     */
    public void incrementCounter(String name) {
        String key = METRICS_PREFIX + name;
        try {
            redisTemplate.opsForValue().increment(key);
            redisTemplate.expire(key, 1, TimeUnit.HOURS);
        } catch (Exception e) {
            log.error("增加计数器失败: {}", e.getMessage());
        }
    }

    /**
     * 发送告警
     */
    public void sendAlert(String level, String message) {
        String key = ALERT_PREFIX + level + ":" + System.currentTimeMillis();
        try {
            Map<String, String> alert = new HashMap<>();
            alert.put("level", level);
            alert.put("message", message);
            alert.put("timestamp", String.valueOf(System.currentTimeMillis()));
            
            redisTemplate.opsForHash().putAll(key, alert);
            redisTemplate.expire(key, 24, TimeUnit.HOURS);
            
            log.warn("发送告警: level={}, message={}", level, message);
            
            // 这里可以集成邮件、短信等通知方式
            if ("CRITICAL".equals(level)) {
                sendCriticalAlert(message);
            }
        } catch (Exception e) {
            log.error("发送告警失败: {}", e.getMessage());
        }
    }

    /**
     * 发送严重告警
     */
    private void sendCriticalAlert(String message) {
        log.error("严重告警: {}", message);
        // TODO: 集成邮件或短信通知
    }

    /**
     * 定时检查系统状态
     */
    @Scheduled(fixedRate = 60000)
    public void checkSystemStatus() {
        try {
            // 检查内存使用率
            Runtime runtime = Runtime.getRuntime();
            long maxMemory = runtime.maxMemory();
            long usedMemory = runtime.totalMemory() - runtime.freeMemory();
            double memoryUsagePct = (double) usedMemory / maxMemory * 100;

            recordMetric("system.memory.usage", memoryUsagePct);
            memoryUsage.set((long) memoryUsagePct);

            if (memoryUsagePct > 90) {
                sendAlert("CRITICAL", String.format("内存使用率过高: %.2f%%", memoryUsagePct));
            } else if (memoryUsagePct > 80) {
                sendAlert("WARNING", String.format("内存使用率较高: %.2f%%", memoryUsagePct));
            }

            // 检查线程数
            int tc = Thread.activeCount();
            recordMetric("system.thread.count", tc);
            threadCount.set(tc);

            if (tc > 200) {
                sendAlert("WARNING", String.format("线程数过多: %d", tc));
            }

        } catch (Exception e) {
            log.error("检查系统状态失败: {}", e.getMessage());
        }
    }
}
