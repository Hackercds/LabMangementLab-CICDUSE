/**
 * 实验室管理系统 - MCP Playwright 测试模块
 *
 * 通过 MCP Playwright Server 在 Claude Code 中直接调用浏览器进行 E2E 测试。
 * 也可以在 @playwright/mcp 的 session 中逐步骤调用。
 *
 * 使用前提:
 *   1. 前端运行中: cd frontend && npm run dev (端口 3000)
 *   2. 后端运行中: cd backend && mvn spring-boot:run (端口 8081)
 *   3. MCP Playwright Server 已配置
 *
 * Claude Code MCP 配置示例 (settings.json):
 *   "mcpServers": {
 *     "playwright": {
 *       "command": "npx",
 *       "args": ["@playwright/mcp@latest"]
 *     }
 *   }
 */

const BASE = 'http://localhost:3000';
const API  = 'http://localhost:8081/api';

/**
 * 通过 MCP Playwright 可执行的测试步骤。
 * 每个函数返回 { page, context } 供后续步骤复用。
 */

// ---- 辅助函数 ----

/** 打开登录页 */
async function openLoginPage(browser) {
  const page = await browser.newPage();
  await page.goto(`${BASE}/#/login`);
  return page;
}

/** 执行登录 */
async function login(page, username = 'admin', password = 'admin123') {
  await page.fill('input[placeholder="请输入学号/工号"]', username);
  await page.fill('input[placeholder="请输入密码"]', password);
  await page.click('button:has-text("登录")');
  await page.waitForURL('**/admin/**', { timeout: 10000 });
}

// ---- 测试场景 ----

/**
 * 场景1: 验证登录页面元素
 * MCP 调用: 告诉 Claude "用 Playwright 打开 localhost:3000/#/login 检查页面"
 */
async function scenario_login_page() {
  // Claude 通过 MCP 逐步执行:
  // 1. browser_navigate → http://localhost:3000/#/login
  // 2. browser_snapshot → 检查是否存在输入框和登录按钮
  return {
    url: `${BASE}/#/login`,
    expectedElements: [
      'input[placeholder="请输入学号/工号"]',
      'input[placeholder="请输入密码"]',
      'button:has-text("登录")'
    ]
  };
}

/**
 * 场景2: 登录 + 跳转仪表盘
 * MCP 调用: 告诉 Claude "登录 admin/admin123 并验证跳转"
 */
async function scenario_login_and_redirect(page) {
  await login(page);
  const url = page.url();
  return {
    success: url.includes('/admin/'),
    currentUrl: url
  };
}

/**
 * 场景3: 创建预约
 * MCP 调用: 告诉 Claude "以 admin 身份预约实验室"
 */
async function scenario_create_reservation(page) {
  await login(page);
  await page.goto(`${BASE}/#/student/reservation`);
  await page.waitForSelector('.el-select');

  // 选实验室
  await page.click('.el-select');
  await page.waitForSelector('.el-select-dropdown__item');
  await page.click('.el-select-dropdown__item:first-child');

  // 选日期
  await page.click('.el-date-editor input');
  await page.click('.el-date-table td.today, .el-date-table td.current');

  // 选时间段
  await page.waitForSelector('.free');
  await page.click('.free:first-child');

  // 填写事由
  await page.fill('input[placeholder="请输入预约事由"]', 'MCP自动化测试');

  // 提交
  await page.click('button:has-text("提交预约申请")');
  await page.waitForTimeout(2000);

  return { submitted: true };
}

/**
 * 场景4: 设备借用
 * MCP 调用: 告诉 Claude "借用第一个可用的设备"
 */
async function scenario_borrow_device(page) {
  await login(page);
  await page.goto(`${BASE}/#/student/device`);
  await page.waitForSelector('.el-table');

  // 找第一个可借用的设备
  const borrowBtn = page.locator('button:has-text("申请借用"):not([disabled])').first();
  if (await borrowBtn.count() === 0) {
    return { borrowed: false, reason: '没有可借用的设备' };
  }

  await borrowBtn.click();
  await page.waitForSelector('.el-dialog');

  // 选归还日期（7天后）
  const nextWeek = new Date();
  nextWeek.setDate(nextWeek.getDate() + 7);
  const dateStr = nextWeek.toISOString().split('T')[0];
  await page.fill('.el-date-picker input', dateStr);
  await page.keyboard.press('Enter');

  // 确认借用
  await page.click('button:has-text("提交借用申请")');
  await page.waitForTimeout(2000);

  return { borrowed: true };
}

/**
 * 场景5: 耗材领用
 * MCP 调用: 告诉 Claude "打开耗材管理页面验证列表"
 */
async function scenario_consumable_list(page) {
  await login(page);
  await page.goto(`${BASE}/#/admin/consumable`);
  await page.waitForSelector('.el-table');

  const rows = await page.locator('.el-table__body tr').count();
  return { rowCount: rows };
}

// ---- MCP 入口 ----
// 在 Claude Code 中启用 MCP Playwright 后，直接告诉 Claude:
//
//   "帮我运行登录测试: 打开 localhost:3000/#/login,
//    用 admin/admin123 登录, 验证跳转到仪表盘"
//
// Claude 会通过 MCP 逐步调用 Playwright 完成。

module.exports = {
  BASE, API,
  openLoginPage,
  login,
  scenario_login_page,
  scenario_login_and_redirect,
  scenario_create_reservation,
  scenario_borrow_device,
  scenario_consumable_list,
};
