package com.labmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 应用配置属性
 */
@Data
@Component
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    /**
     * 应用名称
     */
    private String name;

    /**
     * 应用版本
     */
    private String version;

    /**
     * 应用描述
     */
    private String description;

    /**
     * 跨域配置
     */
    private CorsProperties cors;

    /**
     * 安全配置
     */
    private SecurityProperties security;

    /**
     * 文件存储配置
     */
    private StorageProperties storage;

    /**
     * 业务配置
     */
    private BusinessProperties business;

    /**
     * 通知配置
     */
    private NotificationProperties notification;

    @Data
    public static class CorsProperties {
        /**
         * 允许的源
         */
        private String allowedOrigins;

        /**
         * 允许的方法
         */
        private String allowedMethods;

        /**
         * 允许的头
         */
        private String allowedHeaders;

        /**
         * 是否允许凭证
         */
        private Boolean allowCredentials;

        /**
         * 最大缓存时间
         */
        private Long maxAge;
    }

    @Data
    public static class SecurityProperties {
        /**
         * 忽略的URL
         */
        private String ignoreUrls;

        /**
         * 限流配置
         */
        private RateLimitProperties rateLimit;
    }

    @Data
    public static class RateLimitProperties {
        /**
         * 是否启用
         */
        private Boolean enabled;

        /**
         * 每分钟请求数
         */
        private Integer requestsPerMinute;
    }

    @Data
    public static class StorageProperties {
        /**
         * 存储类型
         */
        private String type;

        /**
         * 本地存储配置
         */
        private LocalStorageProperties local;

        /**
         * 最大文件大小
         */
        private String maxSize;

        /**
         * 允许的文件类型
         */
        private String allowedTypes;
    }

    @Data
    public static class LocalStorageProperties {
        /**
         * 存储路径
         */
        private String path;
    }

    @Data
    public static class BusinessProperties {
        /**
         * 预约配置
         */
        private ReservationProperties reservation;

        /**
         * 设备配置
         */
        private DeviceProperties device;

        /**
         * 耗材配置
         */
        private ConsumableProperties consumable;
    }

    @Data
    public static class ReservationProperties {
        /**
         * 最大提前预约天数
         */
        private Integer maxDaysInAdvance;

        /**
         * 最小提前预约小时数
         */
        private Integer minHoursInAdvance;

        /**
         * 每天最大预约小时数
         */
        private Integer maxHoursPerDay;

        /**
         * 取消预约提前小时数
         */
        private Integer cancelHoursInAdvance;
    }

    @Data
    public static class DeviceProperties {
        /**
         * 最大借用天数
         */
        private Integer maxBorrowDays;

        /**
         * 逾期罚款（每天）
         */
        private Double overdueFinePerDay;
    }

    @Data
    public static class ConsumableProperties {
        /**
         * 预警阈值
         */
        private Integer warningThreshold;

        /**
         * 是否启用自动预警
         */
        private Boolean autoWarningEnabled;
    }

    @Data
    public static class NotificationProperties {
        /**
         * 邮件配置
         */
        private EmailProperties email;

        /**
         * 短信配置
         */
        private SmsProperties sms;
    }

    @Data
    public static class EmailProperties {
        /**
         * 是否启用
         */
        private Boolean enabled;

        /**
         * SMTP主机
         */
        private String host;

        /**
         * SMTP端口
         */
        private Integer port;

        /**
         * 用户名
         */
        private String username;

        /**
         * 密码
         */
        private String password;

        /**
         * 发件人
         */
        private String from;
    }

    @Data
    public static class SmsProperties {
        /**
         * 是否启用
         */
        private Boolean enabled;

        /**
         * 服务提供商
         */
        private String provider;

        /**
         * 访问密钥
         */
        private String accessKey;

        /**
         * 私密密钥
         */
        private String secretKey;
    }
}
