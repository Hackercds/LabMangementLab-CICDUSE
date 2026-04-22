package com.labmanagement.controller;

import com.labmanagement.common.result.Result;
import com.labmanagement.entity.User;
import com.labmanagement.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 认证控制器
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Data
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    public static class RegisterRequest {
        private String username;
        private String password;
        private String realName;
        private String role;
    }

    @Data
    public static class ChangePasswordRequest {
        private String oldPassword;
        private String newPassword;
    }

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<AuthService.LoginResponse> login(@RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        String ipAddress = httpRequest.getRemoteAddr();
        AuthService.LoginResponse response = authService.login(request.getUsername(), request.getPassword(), ipAddress);
        return Result.success(response);
    }

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<Void> register(@RequestBody RegisterRequest request) {
        authService.register(request.getUsername(), request.getPassword(), request.getRealName(), request.getRole());
        return Result.success();
    }

    /**
     * 获取当前用户信息
     */
    @GetMapping("/me")
    public Result<User> me(@RequestAttribute Long userId) {
        User user = authService.getCurrentUser(userId);
        return Result.success(user);
    }

    /**
     * 修改密码
     */
    @PutMapping("/password")
    public Result<Void> changePassword(@RequestBody ChangePasswordRequest request, @RequestAttribute Long userId) {
        authService.changePassword(userId, request.getOldPassword(), request.getNewPassword());
        return Result.success();
    }
}
