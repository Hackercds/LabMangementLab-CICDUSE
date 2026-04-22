package com.labmanagement.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.labmanagement.common.exception.BusinessException;
import com.labmanagement.entity.User;
import com.labmanagement.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 用户管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final OperationLogService operationLogService;

    /**
     * 分页查询用户列表
     */
    public IPage<User> pageList(Integer current, Integer size, String keyword, String role, String status) {
        Page<User> page = new Page<>(current, size);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.orderByDesc(User::getCreateTime);

        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(User::getUsername, keyword).or().like(User::getRealName, keyword));
        }
        if (StringUtils.hasText(role)) {
            wrapper.eq(User::getRole, role);
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(User::getStatus, status);
        }

        return userMapper.selectPage(page, wrapper);
    }

    /**
     * 获取用户详情
     */
    public User getById(Long id) {
        User user = userMapper.selectById(id);
        user.setPassword(null);
        return user;
    }

    /**
     * 新增用户
     */
    @Transactional
    public void create(User user, Long operatorId) {
        // 检查用户名重复
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, user.getUsername());
        if (userMapper.selectCount(wrapper) > 0) {
            throw new BusinessException(400, "用户名已存在");
        }

        // 默认密码设置为123456
        if (!StringUtils.hasText(user.getPassword())) {
            user.setPassword(passwordEncoder.encode("123456"));
        } else {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        user.setCreateTime(LocalDateTime.now());
        user.setCreateBy(operatorId);
        if (!StringUtils.hasText(user.getStatus())) {
            user.setStatus("ENABLED");
        }

        userMapper.insert(user);
        operationLogService.log(operatorId, "CREATE", "USER", "新增用户: " + user.getUsername(), null);
    }

    /**
     * 更新用户
     */
    @Transactional
    public void update(Long id, User user, Long operatorId) {
        user.setId(id);
        user.setPassword(null); // 不更新密码
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);
        operationLogService.log(operatorId, "UPDATE", "USER", "更新用户: " + id, null);
    }

    /**
     * 删除用户
     */
    @Transactional
    public void delete(Long id, Long operatorId) {
        userMapper.deleteById(id);
        operationLogService.log(operatorId, "DELETE", "USER", "删除用户: " + id, null);
    }

    /**
     * 修改用户状态
     */
    @Transactional
    public void changeStatus(Long id, String status, Long operatorId) {
        User user = new User();
        user.setId(id);
        user.setStatus(status);
        userMapper.updateById(user);
        operationLogService.log(operatorId, "CHANGE_STATUS", "USER", "修改用户状态: " + id + " -> " + status, null);
    }
}
