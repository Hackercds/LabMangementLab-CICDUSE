@echo off
chcp 65001 >nul
echo ========================================
echo 实验室管理系统 - 快速部署脚本
echo ========================================
echo.

echo [1/5] 检查环境...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ✗ Docker未安装，请先安装Docker Desktop
    pause
    exit /b 1
)
echo ✓ Docker已安装

where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    echo ✗ Docker Compose未安装
    pause
    exit /b 1
)
echo ✓ Docker Compose已安装
echo.

echo [2/5] 创建环境配置文件...
if not exist .env (
    echo 📝 创建.env文件...
    copy .env.template .env >nul
    echo ✓ .env文件已创建，请编辑配置
    notepad .env
) else (
    echo ✓ .env文件已存在
)
echo.

echo [3/5] 构建并启动服务...
echo 🚀 启动Docker容器...
docker-compose up -d --build
if %errorlevel% neq 0 (
    echo ✗ 服务启动失败
    pause
    exit /b 1
)
echo ✓ 服务启动成功
echo.

echo [4/5] 等待服务就绪...
timeout /t 30 /nobreak >nul
echo ✓ 等待完成
echo.

echo [5/5] 运行冒烟测试...
cd tests
if not exist requirements.txt (
    echo ⚠️ 测试目录不存在，跳过冒烟测试
) else (
    echo 🧪 安装测试依赖...
    pip install -r requirements.txt -q
    echo 🧪 运行冒烟测试...
    python run_tests.py smoke
    if %errorlevel% neq 0 (
        echo ⚠️ 冒烟测试失败，请检查服务状态
    ) else (
        echo ✓ 冒烟测试通过
    )
)
cd ..
echo.

echo ========================================
echo ✅ 部署完成！
echo ========================================
echo.
echo 📊 服务状态:
docker-compose ps
echo.
echo 🌐 访问地址:
echo    前端: http://localhost
echo    后端: http://localhost:8081/api
echo.
echo 📝 默认账号:
echo    管理员: admin / admin123
echo    教师: teacher / 123456
echo    学生: student / 123456
echo.
echo 📋 常用命令:
echo    查看日志: docker-compose logs -f
echo    停止服务: docker-compose down
echo    重启服务: docker-compose restart
echo.
pause
