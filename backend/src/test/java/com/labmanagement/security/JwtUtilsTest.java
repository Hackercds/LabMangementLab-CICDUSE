package com.labmanagement.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;

/**
 * JWT工具类单元测试
 */
@ExtendWith(MockitoExtension.class)
public class JwtUtilsTest {

    private JwtUtils jwtUtils;

    @BeforeEach
    public void setUp() {
        jwtUtils = new JwtUtils();
        // 使用反射设置测试值
        try {
            java.lang.reflect.Field secretField = JwtUtils.class.getDeclaredField("secret");
            secretField.setAccessible(true);
            secretField.set(jwtUtils, "test-secret-key-for-unit-testing");
            java.lang.reflect.Field expirationField = JwtUtils.class.getDeclaredField("expiration");
            expirationField.setAccessible(true);
            expirationField.set(jwtUtils, 3600000L); // 1 hour
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 测试token生成和解析
     */
    @Test
    public void testGenerateAndParseToken() {
        // Given
        Long userId = 123L;
        String role = "ADMIN";

        // When
        String token = jwtUtils.generateToken(userId, role);
        Long parsedUserId = jwtUtils.getUserIdFromToken(token);
        String parsedRole = jwtUtils.getRoleFromToken(token);
        boolean isValid = jwtUtils.validateToken(token);

        // Then
        assertNotNull(token);
        assertTrue(isValid);
        assertEquals(userId, parsedUserId);
        assertEquals(role, parsedRole);
    }

    /**
     * 测试过期token验证失败
     */
    @Test
    public void testInvalidToken_expired() {
        // Given an invalid token
        String invalidToken = "this-is-not-a-valid-token";

        // When
        boolean isValid = jwtUtils.validateToken(invalidToken);

        // Then
        assertFalse(isValid);
    }

    /**
     * 测试被篡改的token验证失败
     */
    @Test
    public void testInvalidToken_tampered() {
        // Given
        String token = jwtUtils.generateToken(123L, "ADMIN");
        String tamperedToken = token + "x";

        // When
        boolean isValid = jwtUtils.validateToken(tamperedToken);

        // Then
        assertFalse(isValid);
    }
}
