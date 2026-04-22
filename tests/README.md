# 实验室管理系统API自动化测试框架

## 📋 项目简介

企业级API自动化测试框架，基于Python + Pytest + Allure构建，支持数据驱动、并行测试、自动报告生成等特性。

## 🚀 快速开始

### 1. 安装依赖

```bash
cd tests
pip install -r requirements.txt
```

### 2. 运行测试

```bash
# 运行完整测试套件
python run_tests.py full

# 运行冒烟测试
python run_tests.py smoke

# 运行回归测试
python run_tests.py regression

# 运行指定模块测试
python run_tests.py module --module auth

# 并行运行测试
python run_tests.py parallel --workers 4

# 运行失败的测试
python run_tests.py failed
```

### 3. 生成报告

```bash
# 生成Allure报告
python run_tests.py report

# 打开Allure报告
python run_tests.py open
```

## 📁 项目结构

```
tests/
├── conftest.py              # 测试配置和夹具
├── pytest.ini               # Pytest配置文件
├── requirements.txt         # 依赖包列表
├── run_tests.py            # 测试运行脚本
├── test_auth.py            # 认证模块测试
├── test_reservation.py     # 预约模块测试
├── test_lab.py             # 实验室模块测试
├── test_device.py          # 设备模块测试
├── test_consumable.py      # 耗材模块测试
├── test_announcement.py    # 公告模块测试
├── test_statistics.py      # 统计模块测试
└── reports/                # 测试报告目录
    ├── allure-results/     # Allure原始数据
    ├── allure-report/      # Allure HTML报告
    └── *.html              # Pytest HTML报告
```

## 🎯 测试覆盖

### 认证模块 (test_auth.py)
- ✅ 用户登录（成功/失败场景）
- ✅ 用户注册
- ✅ 权限验证
- ✅ Token管理

### 预约模块 (test_reservation.py)
- ✅ 预约申请
- ✅ 预约审批
- ✅ 预约查询
- ✅ 预约取消
- ✅ 时间冲突检测

### 实验室模块 (test_lab.py)
- ✅ 实验室创建
- ✅ 实验室查询
- ✅ 实验室更新
- ✅ 实验室删除

### 设备模块 (test_device.py)
- ✅ 设备借用
- ✅ 设备归还
- ✅ 设备查询

### 耗材模块 (test_consumable.py)
- ✅ 耗材入库
- ✅ 耗材领用
- ✅ 库存预警

### 公告模块 (test_announcement.py)
- ✅ 公告发布
- ✅ 公告查询
- ✅ 公告更新
- ✅ 公告删除

### 统计模块 (test_statistics.py)
- ✅ 仪表盘数据
- ✅ 实验室使用率统计
- ✅ 数据导出

## 🔧 测试框架特性

### 1. 数据驱动测试
使用YAML文件管理测试数据，支持参数化测试

### 2. 并行测试
支持多进程并行执行测试用例，提高测试效率

### 3. 失败重试
失败的测试用例自动重试，减少误报

### 4. 多种报告格式
- Pytest HTML报告
- Allure交互式报告
- JSON格式报告

### 5. 自动化断言
封装常用断言方法，提高代码可读性

### 6. 测试数据生成器
自动生成测试数据，避免数据冲突

## 📊 测试报告

### Pytest HTML报告
运行测试后自动生成在 `reports/` 目录下

### Allure报告
```bash
# 生成报告
python run_tests.py report

# 打开报告
python run_tests.py open
```

Allure报告特性：
- 📈 测试趋势图
- 📊 测试统计
- 📝 详细测试步骤
- 📎 请求/响应数据附件
- ⏱️ 性能数据展示

## 🏷️ 测试标记

使用Pytest标记对测试用例分类：

```python
@pytest.mark.smoke          # 冒烟测试
@pytest.mark.regression     # 回归测试
@pytest.mark.api            # API测试
@pytest.mark.auth           # 认证模块
@pytest.mark.reservation    # 预约模块
@pytest.mark.lab            # 实验室模块
```

运行指定标记的测试：
```bash
pytest -m smoke             # 运行冒烟测试
pytest -m "auth and smoke"  # 运行认证模块的冒烟测试
```

## 🔍 断言工具

框架封装了丰富的断言方法：

```python
# 断言请求成功
AssertUtils.assert_success(response, "登录成功")

# 断言请求失败
AssertUtils.assert_failed(response, 401, "未授权")

# 断言响应时间
AssertUtils.assert_response_time(response, 2.0)

# 断言字段存在
AssertUtils.assert_field_exists(data, "token")

# 断言字段值
AssertUtils.assert_field_equals(data, "role", "ADMIN")
```

## 📝 最佳实践

1. **测试数据隔离**：每个测试用例使用独立的测试数据
2. **测试顺序独立**：测试用例之间不依赖执行顺序
3. **清晰的测试步骤**：使用Allure的step功能记录测试步骤
4. **详细的断言信息**：断言失败时提供清晰的错误信息
5. **合理的超时设置**：避免测试用例长时间阻塞

## 🐛 常见问题

### Q: 如何运行单个测试用例？
```bash
pytest test_auth.py::TestLogin::test_admin_login_success -v
```

### Q: 如何查看详细的测试输出？
```bash
pytest -v -s test_auth.py
```

### Q: 如何生成覆盖率报告？
```bash
pytest --cov=. --cov-report=html
```

### Q: 如何在CI/CD中集成？
```bash
# Jenkins Pipeline示例
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'python run_tests.py full'
            }
        }
        stage('Report') {
            steps {
                allure includeProperties: false, jdk: '', results: [[path: 'reports/allure-results']]
            }
        }
    }
}
```

## 📞 联系方式

如有问题，请联系测试团队。

---

**最后更新**: 2026-04-14
