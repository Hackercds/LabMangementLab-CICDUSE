package com.labmanagement.common.retry;

import lombok.extern.slf4j.Slf4j;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Component;

import java.util.function.Supplier;

/**
 * 重试组件
 */
@Slf4j
@Component
public class RetryComponent {

    /**
     * 执行带重试的操作
     *
     * @param operation 操作
     * @param maxAttempts 最大重试次数
     * @param delay 延迟时间（毫秒）
     * @param <T> 返回类型
     * @return 操作结果
     */
    @Retryable(
            value = {Exception.class},
            maxAttempts = 3,
            backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    public <T> T executeWithRetry(Supplier<T> operation, int maxAttempts, long delay) {
        try {
            log.debug("执行操作，最大重试次数: {}, 延迟: {}ms", maxAttempts, delay);
            return operation.get();
        } catch (Exception e) {
            log.warn("操作执行失败: {}", e.getMessage());
            throw e;
        }
    }

    /**
     * 重试失败后的降级处理
     */
    @Recover
    public <T> T recover(Exception e, Supplier<T> operation, int maxAttempts, long delay) {
        log.error("操作重试{}次后仍然失败: {}", maxAttempts, e.getMessage());
        throw new RuntimeException("操作失败，请稍后重试", e);
    }

    /**
     * 执行带重试的无返回值操作
     */
    @Retryable(
            value = {Exception.class},
            maxAttempts = 3,
            backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    public void executeWithRetry(Runnable operation, int maxAttempts, long delay) {
        try {
            log.debug("执行操作，最大重试次数: {}, 延迟: {}ms", maxAttempts, delay);
            operation.run();
        } catch (Exception e) {
            log.warn("操作执行失败: {}", e.getMessage());
            throw e;
        }
    }

    /**
     * 重试失败后的降级处理
     */
    @Recover
    public void recover(Exception e, Runnable operation, int maxAttempts, long delay) {
        log.error("操作重试{}次后仍然失败: {}", maxAttempts, e.getMessage());
        throw new RuntimeException("操作失败，请稍后重试", e);
    }
}
