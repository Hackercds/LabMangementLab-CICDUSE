// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('实验室管理系统 - 预约功能', () => {

  test.beforeEach(async ({ page }) => {
    // 登录
    await page.goto('/#/login');
    await page.getByPlaceholder('请输入学号/工号').fill('admin');
    await page.getByPlaceholder('请输入密码').fill('admin123');
    await page.getByRole('button', { name: '登录' }).click();
    await page.waitForURL('**/admin/**', { timeout: 10000 });
    await page.goto('/#/student/reservation');
    await page.waitForLoadState('networkidle');
  });

  test('页面加载实验室列表', async ({ page }) => {
    await expect(page.locator('.el-select').first()).toBeVisible();
  });

  test('选择实验室和日期后显示时间段网格', async ({ page }) => {
    // 选择第一个实验室
    await page.locator('.el-select').first().click();
    await page.locator('.el-select-dropdown__item').first().click();
    // 选择日期
    const dateInput = page.locator('.el-date-editor input');
    await dateInput.click();
    // 点今天
    await page.locator('.el-date-table td.today, .el-date-table td.current').first().click();
    await page.waitForTimeout(1000);
    // 日历网格应出现
    await expect(page.locator('.calendar-grid')).toBeVisible({ timeout: 5000 });
  });

  test('未选择时间段直接提交应提示', async ({ page }) => {
    // 选实验室
    await page.locator('.el-select').first().click();
    await page.locator('.el-select-dropdown__item').first().click();
    // 选日期
    await page.locator('.el-date-editor input').click();
    await page.locator('.el-date-table td.today, .el-date-table td.current').first().click();
    await page.waitForTimeout(1000);
    // 直接提交
    await page.getByRole('button', { name: '提交预约申请' }).click();
    await expect(page.getByText('请选择至少一个时间段')).toBeVisible({ timeout: 3000 });
  });

});
