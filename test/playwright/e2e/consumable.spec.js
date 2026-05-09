// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('实验室管理系统 - 耗材管理', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/#/login');
    await page.getByPlaceholder('请输入学号/工号').fill('admin');
    await page.getByPlaceholder('请输入密码').fill('admin123');
    await page.getByRole('button', { name: '登录' }).click();
    await page.waitForURL('**/admin/**', { timeout: 10000 });
    await page.goto('/#/admin/consumable');
    await page.waitForLoadState('networkidle');
  });

  test('耗材列表加载正常', async ({ page }) => {
    await expect(page.locator('.el-table')).toBeVisible({ timeout: 5000 });
  });

  test('新增耗材对话框可打开', async ({ page }) => {
    await page.getByRole('button', { name: '新增' }).click();
    await expect(page.locator('.el-dialog')).toBeVisible({ timeout: 3000 });
  });

});
