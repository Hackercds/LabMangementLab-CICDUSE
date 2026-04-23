package com.labmanagement.common.result;

import lombok.Getter;

/**
 * 响应码枚举
 */
@Getter
public enum ResultCode {

    SUCCESS(200, "操作成功"),
    ERROR(500, "服务器错误"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "未认证，请重新登录"),
    FORBIDDEN(403, "权限不足"),
    NOT_FOUND(404, "资源不存在"),
    USER_NOT_FOUND(401, "用户不存在"),
    PASSWORD_ERROR(401, "密码错误"),
    ACCOUNT_DISABLED(401, "账号已被禁用"),
    TIME_CONFLICT(409, "时间段冲突"),
    INSUFFICIENT_STOCK(400, "库存不足"),
    DEVICE_NOT_AVAILABLE(400, "设备当前不可借用"),
    RESERVATION_ALREADY_PROCESSED(400, "预约已处理，不能重复操作");

    private final Integer code;
    private final String message;

    ResultCode(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
}
