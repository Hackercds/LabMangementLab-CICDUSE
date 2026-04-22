package com.labmanagement.common.shutdown;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextClosedEvent;
import org.springframework.stereotype.Component;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 优雅停机组件
 */
@Slf4j
@Component
public class GracefulShutdown implements ApplicationListener<ContextClosedEvent> {

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final AtomicInteger activeRequests = new AtomicInteger(0);
    private volatile boolean shuttingDown = false;

    /**
     * 增加活跃请求计数
     */
    public void incrementRequest() {
        if (shuttingDown) {
            throw new RuntimeException("系统正在关闭，拒绝新请求");
        }
        activeRequests.incrementAndGet();
    }

    /**
     * 减少活跃请求计数
     */
    public void decrementRequest() {
        activeRequests.decrementAndGet();
    }

    /**
     * 是否正在关闭
     */
    public boolean isShuttingDown() {
        return shuttingDown;
    }

    @Override
    public void onApplicationEvent(ContextClosedEvent event) {
        log.info("开始优雅停机...");
        shuttingDown = true;
        
        executor.submit(() -> {
            try {
                int maxWaitSeconds = 30;
                int waitedSeconds = 0;
                
                while (activeRequests.get() > 0 && waitedSeconds < maxWaitSeconds) {
                    log.info("等待活跃请求完成，当前活跃请求数: {}, 已等待: {}秒", 
                            activeRequests.get(), waitedSeconds);
                    TimeUnit.SECONDS.sleep(1);
                    waitedSeconds++;
                }
                
                if (activeRequests.get() > 0) {
                    log.warn("优雅停机超时，强制关闭，剩余活跃请求数: {}", activeRequests.get());
                } else {
                    log.info("所有请求已完成，优雅停机成功");
                }
            } catch (InterruptedException e) {
                log.error("优雅停机被中断", e);
                Thread.currentThread().interrupt();
            }
        });
        
        try {
            executor.shutdown();
            executor.awaitTermination(35, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            log.error("优雅停机等待被中断", e);
            Thread.currentThread().interrupt();
        }
    }
}
