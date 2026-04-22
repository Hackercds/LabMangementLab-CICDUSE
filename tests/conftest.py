"""
实验室管理系统API自动化测试框架
企业级测试套件配置
"""
import pytest
import allure
import requests
import json
import time
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from functools import lru_cache


# ==================== 配置管理 ====================
class Config:
    """测试配置管理"""
    BASE_URL = "http://localhost:8081/api"
    TIMEOUT = 10
    RETRY_COUNT = 3
    
    # 测试账号
    ADMIN_ACCOUNT = {
        "username": "admin",
        "password": "admin123",
        "role": "ADMIN"
    }
    
    TEACHER_ACCOUNT = {
        "username": "teacher",
        "password": "123456",
        "role": "TEACHER"
    }
    
    STUDENT_ACCOUNT = {
        "username": "student",
        "password": "123456",
        "role": "STUDENT"
    }


# ==================== API客户端 ====================
class APIClient:
    """API客户端封装"""
    
    def __init__(self, base_url: str = Config.BASE_URL):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.timeout = Config.TIMEOUT
        self.token = None
    
    def set_token(self, token: str):
        """设置认证Token"""
        self.token = token
        self.session.headers.update({
            "Authorization": f"Bearer {token}"
        })
    
    def clear_token(self):
        """清除认证Token"""
        self.token = None
        if "Authorization" in self.session.headers:
            del self.session.headers["Authorization"]
    
    def request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """发送HTTP请求"""
        url = f"{self.base_url}{endpoint}"
        
        # 添加请求日志到Allure
        with allure.step(f"发送{method}请求: {endpoint}"):
            allure.attach(
                json.dumps(kwargs.get('json', kwargs.get('params', {})), ensure_ascii=False, indent=2),
                "请求参数",
                allure.attachment_type.JSON
            )
            
            response = self.session.request(method, url, **kwargs)
            
            allure.attach(
                f"状态码: {response.status_code}",
                "响应状态",
                allure.attachment_type.TEXT
            )
            
            try:
                allure.attach(
                    json.dumps(response.json(), ensure_ascii=False, indent=2),
                    "响应数据",
                    allure.attachment_type.JSON
                )
            except:
                allure.attach(
                    response.text,
                    "响应内容",
                    allure.attachment_type.TEXT
                )
            
            return response
    
    def get(self, endpoint: str, **kwargs) -> requests.Response:
        return self.request("GET", endpoint, **kwargs)
    
    def post(self, endpoint: str, **kwargs) -> requests.Response:
        return self.request("POST", endpoint, **kwargs)
    
    def put(self, endpoint: str, **kwargs) -> requests.Response:
        return self.request("PUT", endpoint, **kwargs)
    
    def delete(self, endpoint: str, **kwargs) -> requests.Response:
        return self.request("DELETE", endpoint, **kwargs)


# ==================== 测试夹具 ====================
@pytest.fixture(scope="session")
def api_client():
    """API客户端夹具"""
    return APIClient()


@pytest.fixture(scope="session")
def admin_token(api_client):
    """管理员Token夹具"""
    response = api_client.post("/auth/login", json=Config.ADMIN_ACCOUNT)
    assert response.status_code == 200, "管理员登录失败"
    data = response.json()
    assert data["code"] == 200, f"登录失败: {data.get('message')}"
    token = data["data"]["token"]
    yield token
    api_client.clear_token()


@pytest.fixture(scope="session")
def teacher_token(api_client):
    """教师Token夹具"""
    # 先尝试注册教师账号
    api_client.post("/auth/register", json={
        "username": "teacher",
        "password": "123456",
        "realName": "测试教师",
        "role": "TEACHER"
    })
    
    response = api_client.post("/auth/login", json=Config.TEACHER_ACCOUNT)
    if response.status_code == 200:
        data = response.json()
        if data["code"] == 200:
            token = data["data"]["token"]
            yield token
            api_client.clear_token()
            return
    
    yield None


@pytest.fixture(scope="session")
def student_token(api_client):
    """学生Token夹具"""
    # 先尝试注册学生账号
    api_client.post("/auth/register", json={
        "username": "student",
        "password": "123456",
        "realName": "测试学生",
        "role": "STUDENT"
    })
    
    response = api_client.post("/auth/login", json=Config.STUDENT_ACCOUNT)
    if response.status_code == 200:
        data = response.json()
        if data["code"] == 200:
            token = data["data"]["token"]
            yield token
            api_client.clear_token()
            return
    
    yield None


@pytest.fixture(scope="function")
def admin_client(api_client, admin_token):
    """管理员客户端夹具"""
    api_client.set_token(admin_token)
    yield api_client
    api_client.clear_token()


@pytest.fixture(scope="function")
def teacher_client(api_client, teacher_token):
    """教师客户端夹具"""
    if teacher_token:
        api_client.set_token(teacher_token)
    yield api_client
    api_client.clear_token()


@pytest.fixture(scope="function")
def student_client(api_client, student_token):
    """学生客户端夹具"""
    if student_token:
        api_client.set_token(student_token)
    yield api_client
    api_client.clear_token()


# ==================== 测试数据夹具 ====================
@pytest.fixture(scope="session")
def test_lab(admin_client):
    """测试实验室夹具"""
    lab_data = DataGenerator.generate_lab_data()
    response = admin_client.post("/lab", json=lab_data)
    
    if response.status_code == 200 and response.json()["code"] == 200:
        # 获取实验室列表，找到刚创建的实验室
        list_response = admin_client.get("/lab/list")
        if list_response.status_code == 200:
            labs = list_response.json()["data"]
            for lab in labs:
                if lab["name"] == lab_data["name"]:
                    yield lab
                    return
    
    # 如果创建失败，返回一个默认的实验室
    yield {"id": 1, "name": "默认实验室"}


@pytest.fixture(scope="function")
def pending_reservation(admin_client, test_lab):
    """待审批预约夹具"""
    reservation_data = DataGenerator.generate_reservation_data(test_lab["id"])
    response = admin_client.post("/reservation", json=reservation_data)
    
    if response.status_code == 200 and response.json()["code"] == 200:
        # 获取预约列表，找到刚创建的预约
        list_response = admin_client.get("/reservation/list", params={
            "current": 1,
            "size": 1,
            "status": "PENDING"
        })
        if list_response.status_code == 200:
            records = list_response.json()["data"]["records"]
            if records:
                yield records[0]
                return
    
    # 如果创建失败，返回一个默认的预约
    yield {"id": 1, "status": "PENDING"}


@pytest.fixture(scope="function")
def approved_reservation(admin_client, pending_reservation):
    """已审批预约夹具"""
    response = admin_client.put(
        f"/reservation/{pending_reservation['id']}/approve",
        params={"status": "APPROVED", "comment": "审批通过"}
    )
    
    if response.status_code == 200:
        yield pending_reservation
    else:
        yield pending_reservation


# ==================== 测试数据生成器 ====================
class DataGenerator:
    """测试数据生成器"""
    
    @staticmethod
    def generate_user_data(suffix: str = None) -> Dict[str, Any]:
        """生成用户测试数据"""
        timestamp = int(time.time() * 1000)
        suffix = suffix or timestamp
        return {
            "username": f"testuser_{suffix}",
            "password": "123456",
            "realName": f"测试用户_{suffix}",
            "role": "STUDENT"
        }
    
    @staticmethod
    def generate_lab_data(suffix: str = None) -> Dict[str, Any]:
        """生成实验室测试数据"""
        timestamp = int(time.time() * 1000)
        suffix = suffix or timestamp
        return {
            "name": f"测试实验室_{suffix}",
            "location": f"{suffix % 10 + 1}号楼{suffix % 100 + 1}室",
            "capacity": 30 + (suffix % 50),
            "deviceCount": 20 + (suffix % 30),
            "status": "FREE",
            "director": "测试负责人",
            "phone": "13800138000"
        }
    
    @staticmethod
    def generate_reservation_data(lab_id: int, date: str = None) -> Dict[str, Any]:
        """生成预约测试数据"""
        if not date:
            date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        return {
            "labId": lab_id,
            "reservationDate": date,
            "startTime": "09:00",
            "endTime": "11:00",
            "purpose": "自动化测试预约",
            "participantCount": 10
        }
    
    @staticmethod
    def generate_device_data(lab_id: int, suffix: str = None) -> Dict[str, Any]:
        """生成设备测试数据"""
        timestamp = int(time.time() * 1000)
        suffix = suffix or timestamp
        return {
            "name": f"测试设备_{suffix}",
            "model": f"Model-{suffix}",
            "serialNumber": f"SN{timestamp}",
            "labId": lab_id,
            "purchaseDate": datetime.now().strftime("%Y-%m-%d"),
            "status": "NORMAL"
        }
    
    @staticmethod
    def generate_consumable_data(suffix: str = None) -> Dict[str, Any]:
        """生成耗材测试数据"""
        timestamp = int(time.time() * 1000)
        suffix = suffix or timestamp
        return {
            "name": f"测试耗材_{suffix}",
            "specification": "标准规格",
            "unit": "个",
            "currentStock": 100,
            "warningThreshold": 10,
            "location": f"储物柜{suffix % 10 + 1}"
        }
    
    @staticmethod
    def generate_announcement_data(suffix: str = None) -> Dict[str, Any]:
        """生成公告测试数据"""
        timestamp = int(time.time() * 1000)
        suffix = suffix or timestamp
        return {
            "title": f"测试公告_{suffix}",
            "content": f"这是测试公告内容_{suffix}",
            "isTop": False,
            "status": "PUBLISHED"
        }


# ==================== 断言工具 ====================
class AssertUtils:
    """断言工具类"""
    
    @staticmethod
    def assert_success(response: requests.Response, message: str = "请求成功"):
        """断言请求成功"""
        with allure.step(f"断言: {message}"):
            assert response.status_code == 200, f"HTTP状态码错误: {response.status_code}"
            data = response.json()
            assert data["code"] == 200, f"业务状态码错误: {data.get('message')}"
            allure.attach(
                f"断言通过: {message}",
                "断言结果",
                allure.attachment_type.TEXT
            )
    
    @staticmethod
    def assert_failed(response: requests.Response, expected_code: int = None, message: str = "请求失败"):
        """断言请求失败"""
        with allure.step(f"断言: {message}"):
            if expected_code:
                data = response.json()
                assert data["code"] == expected_code, f"错误码不匹配: 期望{expected_code}, 实际{data['code']}"
            allure.attach(
                f"断言通过: {message}",
                "断言结果",
                allure.attachment_type.TEXT
            )
    
    @staticmethod
    def assert_response_time(response: requests.Response, max_time: float = 2.0):
        """断言响应时间"""
        with allure.step(f"断言响应时间 < {max_time}秒"):
            elapsed = response.elapsed.total_seconds()
            assert elapsed < max_time, f"响应时间过长: {elapsed:.2f}秒"
            allure.attach(
                f"响应时间: {elapsed:.2f}秒",
                "性能数据",
                allure.attachment_type.TEXT
            )
    
    @staticmethod
    def assert_data_not_empty(data: Any, field_name: str = "数据"):
        """断言数据不为空"""
        with allure.step(f"断言{field_name}不为空"):
            assert data, f"{field_name}为空"
            if isinstance(data, (list, dict)):
                assert len(data) > 0, f"{field_name}为空"
            allure.attach(
                f"{field_name}验证通过",
                "断言结果",
                allure.attachment_type.TEXT
            )
    
    @staticmethod
    def assert_field_exists(data: Dict, field: str):
        """断言字段存在"""
        with allure.step(f"断言字段'{field}'存在"):
            assert field in data, f"字段'{field}'不存在"
            allure.attach(
                f"字段'{field}': {data[field]}",
                "字段值",
                allure.attachment_type.TEXT
            )
    
    @staticmethod
    def assert_field_equals(data: Dict, field: str, expected: Any):
        """断言字段值相等"""
        with allure.step(f"断言字段'{field}'等于'{expected}'"):
            assert field in data, f"字段'{field}'不存在"
            assert data[field] == expected, f"字段'{field}'值不匹配: 期望{expected}, 实际{data[field]}"
            allure.attach(
                f"字段'{field}'验证通过",
                "断言结果",
                allure.attachment_type.TEXT
            )


# ==================== 测试报告钩子 ====================
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """测试报告钩子 - 失败时截图"""
    outcome = yield
    report = outcome.get_result()
    
    if report.when == "call" and report.failed:
        # 失败时添加额外信息到Allure报告
        allure.attach(
            f"测试失败: {item.name}",
            "失败信息",
            allure.attachment_type.TEXT
        )


def pytest_collection_modifyitems(config, items):
    """测试收集修改 - 添加标记"""
    for item in items:
        # 根据文件名自动添加标记
        if "auth" in item.fspath.basename:
            item.add_marker(pytest.mark.auth)
        elif "reservation" in item.fspath.basename:
            item.add_marker(pytest.mark.reservation)
        elif "lab" in item.fspath.basename:
            item.add_marker(pytest.mark.lab)
        elif "device" in item.fspath.basename:
            item.add_marker(pytest.mark.device)
        elif "statistics" in item.fspath.basename:
            item.add_marker(pytest.mark.statistics)
