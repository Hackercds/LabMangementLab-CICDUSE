// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('实验室管理系统 - 设备管理', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/#/login');
    await page.getByPlaceholder('请输入学号/工号').fill('admin');
    await page.getByPlaceholder('请输入密码').fill('admin123');
    await page.getByRole('button', { name: '登录' }).click();
    await page.waitForURL('**/admin/**', { timeout: 10000 });
    await page.goto('/#/student/device');
    await page.waitForLoadState('networkidle');
  });

  test('设备列表加载正常', async ({ page }) => {
    await expect(page.locator('.el-table')).toBeVisible({ timeout: 5000 });
  });

  test('借用对话框可打开', async ({ page }) => {
    await page.waitForSelector('.el-table');
    const borrowBtn = page.locator('.el-button', { hasText: '申请借用' }).first();
    if (await borrowBtn.isEnabled()) {
      await borrowBtn.click();
      await expect(page.locator('.el-dialog')).toBeVisible({ timeout: 3000 });
    }
  });

});
