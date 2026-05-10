package com.labmanagement.common.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.labmanagement.entity.User;
import com.labmanagement.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 启动时自动初始化/重置管理员账号
 * 密码: admin123 (每次部署自动重置)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminInitializer implements CommandLineRunner {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        String defaultPassword = "admin123";
        String hash = passwordEncoder.encode(defaultPassword);

        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, "admin");
        User admin = userMapper.selectOne(wrapper);

        if (admin == null) {
            admin = new User();
            admin.setUsername("admin");
            admin.setPassword(hash);
            admin.setRealName("系统管理员");
            admin.setRole("ADMIN");
            admin.setStatus("ENABLED");
            userMapper.insert(admin);
            log.info("管理员账号已创建: admin / {}", defaultPassword);
        } else {
            admin.setPassword(hash);
            admin.setStatus("ENABLED");
            admin.setRole("ADMIN");
            userMapper.updateById(admin);
            log.info("管理员密码已重置: admin / {}", defaultPassword);
        }
    }
}
