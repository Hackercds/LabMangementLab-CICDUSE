// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('实验室管理系统 - 登录功能', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/#/login');
  });

  test('登录页面渲染正确', async ({ page }) => {
    await expect(page.getByPlaceholder('请输入学号/工号')).toBeVisible();
    await expect(page.getByPlaceholder('请输入密码')).toBeVisible();
    await expect(page.getByRole('button', { name: '登录' })).toBeVisible();
  });

  test('空输入提交应显示验证提示', async ({ page }) => {
    await page.getByRole('button', { name: '登录' }).click();
    await expect(page.locator('.el-form-item__error').first()).toBeVisible();
  });

  test('错误密码应显示错误消息', async ({ page }) => {
    await page.getByPlaceholder('请输入学号/工号').fill('admin');
    await page.getByPlaceholder('请输入密码').fill('wrongpassword');
    await page.getByRole('button', { name: '登录' }).click();
    await expect(page.locator('.el-message--error')).toBeVisible({ timeout: 5000 });
  });

  test('正确密码应登录成功并跳转', async ({ page }) => {
    await page.getByPlaceholder('请输入学号/工号').fill('admin');
    await page.getByPlaceholder('请输入密码').fill('admin123');
    await page.getByRole('button', { name: '登录' }).click();
    await page.waitForURL('**/admin/**', { timeout: 10000 });
    await expect(page).toHaveURL(/\/admin\//);
  });

});
