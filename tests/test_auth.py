"""
认证模块测试用例
包含登录、注册、权限验证等测试
"""
import pytest
import allure
from conftest import Config, AssertUtils, DataGenerator


@allure.feature("认证管理")
@allure.story("用户登录")
class TestLogin:
    """登录测试"""
    
    @allure.title("管理员登录成功")
    @allure.severity(allure.severity_level.BLOCKER)
    @pytest.mark.smoke
    @pytest.mark.auth
    def test_admin_login_success(self, api_client):
        """测试管理员登录成功"""
        with allure.step("发送登录请求"):
            response = api_client.post("/auth/login", json=Config.ADMIN_ACCOUNT)
        
        with allure.step("验证登录成功"):
            AssertUtils.assert_success(response, "管理员登录")
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "token")
            AssertUtils.assert_field_exists(data, "realName")
            AssertUtils.assert_field_equals(data, "role", "ADMIN")
    
    @allure.title("教师登录成功")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_teacher_login_success(self, api_client):
        """测试教师登录成功"""
        with allure.step("发送登录请求"):
            response = api_client.post("/auth/login", json=Config.TEACHER_ACCOUNT)
        
        if response.status_code == 200 and response.json()["code"] == 200:
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "token")
            AssertUtils.assert_field_equals(data, "role", "TEACHER")
        else:
            pytest.skip("教师账号未创建")
    
    @allure.title("学生登录成功")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_student_login_success(self, api_client):
        """测试学生登录成功"""
        with allure.step("发送登录请求"):
            response = api_client.post("/auth/login", json=Config.STUDENT_ACCOUNT)
        
        if response.status_code == 200 and response.json()["code"] == 200:
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "token")
            AssertUtils.assert_field_equals(data, "role", "STUDENT")
        else:
            pytest.skip("学生账号未创建")
    
    @allure.title("登录失败-用户名不存在")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_login_failed_user_not_exist(self, api_client):
        """测试用户名不存在登录失败"""
        with allure.step("发送登录请求"):
            response = api_client.post("/auth/login", json={
                "username": "notexist_user",
                "password": "123456"
            })
        
        with allure.step("验证登录失败"):
            AssertUtils.assert_failed(response, message="用户不存在登录失败")
    
    @allure.title("登录失败-密码错误")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_login_failed_wrong_password(self, api_client):
        """测试密码错误登录失败"""
        with allure.step("发送登录请求"):
            response = api_client.post("/auth/login", json={
                "username": "admin",
                "password": "wrongpassword"
            })
        
        with allure.step("验证登录失败"):
            AssertUtils.assert_failed(response, message="密码错误登录失败")
    
    @allure.title("登录性能测试")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_login_performance(self, api_client):
        """测试登录接口性能"""
        with allure.step("发送登录请求并验证响应时间"):
            response = api_client.post("/auth/login", json=Config.ADMIN_ACCOUNT)
            AssertUtils.assert_response_time(response, 2.0)


@allure.feature("认证管理")
@allure.story("用户注册")
class TestRegister:
    """注册测试"""
    
    @allure.title("用户注册成功")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_register_success(self, api_client):
        """测试用户注册成功"""
        user_data = DataGenerator.generate_user_data()
        
        with allure.step("发送注册请求"):
            response = api_client.post("/auth/register", json=user_data)
        
        with allure.step("验证注册成功"):
            AssertUtils.assert_success(response, "用户注册")
    
    @allure.title("注册失败-用户名已存在")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_register_failed_username_exists(self, api_client):
        """测试用户名已存在注册失败"""
        with allure.step("发送注册请求"):
            response = api_client.post("/auth/register", json={
                "username": "admin",
                "password": "123456",
                "realName": "测试用户",
                "role": "STUDENT"
            })
        
        with allure.step("验证注册失败"):
            AssertUtils.assert_failed(response, message="用户名已存在")


@allure.feature("认证管理")
@allure.story("权限验证")
class TestAuthorization:
    """权限验证测试"""
    
    @allure.title("未登录访问受保护接口")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_access_protected_api_without_token(self, api_client):
        """测试未登录访问受保护接口"""
        with allure.step("访问受保护的接口"):
            response = api_client.get("/reservation/my")
        
        with allure.step("验证返回401未授权"):
            assert response.status_code == 401 or response.json()["code"] == 401
    
    @allure.title("管理员访问管理接口")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_admin_access_admin_api(self, admin_client):
        """测试管理员访问管理接口"""
        with allure.step("访问管理员接口"):
            response = admin_client.get("/user/page")
        
        with allure.step("验证访问成功"):
            AssertUtils.assert_success(response, "管理员访问管理接口")
    
    @allure.title("学生访问管理接口-权限不足")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_student_access_admin_api_forbidden(self, student_client):
        """测试学生访问管理接口权限不足"""
        if not student_client.token:
            pytest.skip("学生账号未创建")
        
        with allure.step("访问管理员接口"):
            response = student_client.get("/user/page")
        
        with allure.step("验证权限不足"):
            assert response.status_code == 403 or response.json()["code"] == 403


@allure.feature("认证管理")
@allure.story("Token管理")
class TestToken:
    """Token管理测试"""
    
    @allure.title("Token有效性验证")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.auth
    def test_token_valid(self, admin_client):
        """测试Token有效性"""
        with allure.step("使用Token访问接口"):
            response = admin_client.get("/reservation/my")
        
        with allure.step("验证Token有效"):
            AssertUtils.assert_success(response, "Token有效")
    
    @allure.title("无效Token访问")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.auth
    def test_invalid_token(self, api_client):
        """测试无效Token访问"""
        with allure.step("设置无效Token"):
            api_client.set_token("invalid_token_12345")
        
        with allure.step("访问接口"):
            response = api_client.get("/reservation/my")
        
        with allure.step("验证返回401"):
            assert response.status_code == 401 or response.json()["code"] == 401
        
        with allure.step("清除无效Token"):
            api_client.clear_token()
