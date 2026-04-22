@echo off
chcp 65001 >nul
echo ========================================
echo 实验室管理系统API自动化测试
echo ========================================
echo.

echo [1/3] 安装测试依赖...
pip install -r requirements.txt -q
if %errorlevel% neq 0 (
    echo ✗ 依赖安装失败
    pause
    exit /b 1
)
echo ✓ 依赖安装成功
echo.

echo [2/3] 运行冒烟测试...
pytest -m smoke -v --alluredir=./reports/allure-results --clean-alluredir
if %errorlevel% neq 0 (
    echo ✗ 冒烟测试失败
) else (
    echo ✓ 冒烟测试通过
)
echo.

echo [3/3] 生成测试报告...
allure generate ./reports/allure-results -o ./reports/allure-report --clean
if %errorlevel% neq 0 (
    echo ✗ 报告生成失败，请确保已安装Allure命令行工具
    echo 提示: 可以使用 'npm install -g allure-commandline' 安装
) else (
    echo ✓ 报告生成成功
    echo.
    echo 查看报告: allure open ./reports/allure-report
)
echo.

echo ========================================
echo 测试完成！
echo ========================================
pause
