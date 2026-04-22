package com.labmanagement.common.exception;

import com.labmanagement.common.result.ResultCode;
import lombok.Getter;

/**
 * 业务异常
 */
@Getter
public class BusinessException extends RuntimeException {
    
    private final Integer code;
    private final String message;
    
    public BusinessException(String message) {
        super(message);
        this.code = 500;
        this.message = message;
    }
    
    public BusinessException(Integer code, String message) {
        super(message);
        this.code = code;
        this.message = message;
    }
    
    public BusinessException(Integer code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
        this.message = message;
    }
    
    public BusinessException(ResultCode resultCode) {
        super(resultCode.getMessage());
        this.code = resultCode.getCode();
        this.message = resultCode.getMessage();
    }
    
    public static BusinessException of(String message) {
        return new BusinessException(message);
    }
    
    public static BusinessException of(Integer code, String message) {
        return new BusinessException(code, message);
    }
    
    public static BusinessException notFound(String message) {
        return new BusinessException(404, message);
    }
    
    public static BusinessException badRequest(String message) {
        return new BusinessException(400, message);
    }
    
    public static BusinessException unauthorized(String message) {
        return new BusinessException(401, message);
    }
    
    public static BusinessException forbidden(String message) {
        return new BusinessException(403, message);
    }
    
    public static BusinessException conflict(String message) {
        return new BusinessException(409, message);
    }
}
