import asyncio
from playwright.async_api import async_playwright
import time

async def test_reservation_approval():
    """
    测试预约审批功能
    """
    async with async_playwright() as p:
        # 启动浏览器
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context()
        page = await context.new_page()
        
        # 监听控制台错误
        errors = []
        page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)
        
        try:
            # 1. 学生登录并创建预约
            print("=== 步骤1: 学生登录 ===")
            await page.goto("http://localhost:3000/#/login")
            await page.fill('input[placeholder="请输入用户名"]', 'student')
            await page.fill('input[placeholder="请输入密码"]', '123456')
            await page.click('button:has-text("登录")')
            await page.wait_for_timeout(2000)
            
            # 检查是否登录成功
            current_url = page.url
            print(f"当前URL: {current_url}")
            
            # 2. 创建预约申请
            print("\n=== 步骤2: 创建预约申请 ===")
            await page.goto("http://localhost:3000/#/student/reservation")
            await page.wait_for_timeout(1000)
            
            # 选择实验室
            await page.click('.el-select')
            await page.wait_for_timeout(500)
            await page.click('.el-select-dropdown__item:first-child')
            await page.wait_for_timeout(500)
            
            # 选择日期（明天）
            tomorrow = time.strftime("%Y-%m-%d", time.localtime(time.time() + 86400))
            await page.fill('input[placeholder="选择日期"]', tomorrow)
            await page.wait_for_timeout(1000)
            
            # 选择时间段
            await page.click('.calendar-time-slot.free:first-child')
            await page.wait_for_timeout(500)
            
            # 填写预约信息
            await page.fill('input[placeholder="请输入预约事由"]', '测试预约')
            await page.click('button:has-text("提交预约申请")')
            await page.wait_for_timeout(2000)
            
            # 3. 管理员登录并审批预约
            print("\n=== 步骤3: 管理员登录 ===")
            await page.goto("http://localhost:3000/#/login")
            await page.fill('input[placeholder="请输入用户名"]', 'admin')
            await page.fill('input[placeholder="请输入密码"]', 'admin123')
            await page.click('button:has-text("登录")')
            await page.wait_for_timeout(2000)
            
            # 4. 审批预约
            print("\n=== 步骤4: 审批预约 ===")
            await page.goto("http://localhost:3000/#/admin/reservation")
            await page.wait_for_timeout(2000)
            
            # 点击通过按钮
            await page.click('button:has-text("通过")')
            await page.wait_for_timeout(3000)
            
            # 检查是否有错误
            if errors:
                print("\n=== 发现错误 ===")
                for error in errors:
                    print(f"错误: {error}")
            else:
                print("\n=== 测试成功，没有发现错误 ===")
                
        except Exception as e:
            print(f"\n=== 测试失败 ===")
            print(f"错误: {str(e)}")
            import traceback
            traceback.print_exc()
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(test_reservation_approval())
