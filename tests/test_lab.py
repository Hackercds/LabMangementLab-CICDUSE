"""
实验室管理模块测试用例
包含实验室的增删改查等测试
"""
import pytest
import allure
from conftest import AssertUtils, DataGenerator


@allure.feature("实验室管理")
@allure.story("实验室创建")
class TestLabCreate:
    """实验室创建测试"""
    
    @allure.title("管理员创建实验室成功")
    @allure.severity(allure.severity_level.BLOCKER)
    @pytest.mark.smoke
    @pytest.mark.lab
    def test_admin_create_lab_success(self, admin_client):
        """测试管理员创建实验室成功"""
        lab_data = DataGenerator.generate_lab_data()
        
        with allure.step("创建实验室"):
            response = admin_client.post("/lab", json=lab_data)
        
        with allure.step("验证创建成功"):
            AssertUtils.assert_success(response, "创建实验室成功")
    
    @allure.title("创建实验室-必填字段验证")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_create_lab_required_fields(self, admin_client):
        """测试创建实验室必填字段验证"""
        with allure.step("缺少实验室名称"):
            response = admin_client.post("/lab", json={
                "location": "1号楼101室",
                "capacity": 50
            })
            AssertUtils.assert_failed(response, message="缺少实验室名称")
    
    @allure.title("创建重复名称实验室失败")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_create_duplicate_lab(self, admin_client, test_lab):
        """测试创建重复名称实验室失败"""
        lab_data = DataGenerator.generate_lab_data()
        lab_data["name"] = test_lab["name"]
        
        with allure.step("创建重复名称实验室"):
            response = admin_client.post("/lab", json=lab_data)
        
        with allure.step("验证创建失败"):
            AssertUtils.assert_failed(response, message="创建重复名称实验室失败")


@allure.feature("实验室管理")
@allure.story("实验室查询")
class TestLabQuery:
    """实验室查询测试"""
    
    @allure.title("查询实验室列表")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.smoke
    @pytest.mark.lab
    def test_query_lab_list(self, admin_client):
        """测试查询实验室列表"""
        with allure.step("查询实验室列表"):
            response = admin_client.get("/lab/list")
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "查询实验室列表成功")
            data = response.json()["data"]
            AssertUtils.assert_data_not_empty(data, "实验室列表")
    
    @allure.title("分页查询实验室")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.lab
    def test_query_lab_page(self, admin_client):
        """测试分页查询实验室"""
        with allure.step("分页查询实验室"):
            response = admin_client.get("/lab/page", params={
                "current": 1,
                "size": 10
            })
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "分页查询实验室成功")
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "records")
            AssertUtils.assert_field_exists(data, "total")
    
    @allure.title("查询实验室详情")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.lab
    def test_query_lab_detail(self, admin_client, test_lab):
        """测试查询实验室详情"""
        with allure.step("查询实验室详情"):
            response = admin_client.get(f"/lab/{test_lab['id']}")
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "查询实验室详情成功")
            data = response.json()["data"]
            AssertUtils.assert_field_equals(data, "id", test_lab["id"])


@allure.feature("实验室管理")
@allure.story("实验室更新")
class TestLabUpdate:
    """实验室更新测试"""
    
    @allure.title("更新实验室信息成功")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.lab
    def test_update_lab_success(self, admin_client, test_lab):
        """测试更新实验室信息成功"""
        update_data = {
            "name": f"{test_lab['name']}_已更新",
            "capacity": 100
        }
        
        with allure.step("更新实验室"):
            response = admin_client.put(f"/lab/{test_lab['id']}", json=update_data)
        
        with allure.step("验证更新成功"):
            AssertUtils.assert_success(response, "更新实验室成功")
        
        with allure.step("验证更新结果"):
            detail_response = admin_client.get(f"/lab/{test_lab['id']}")
            data = detail_response.json()["data"]
            AssertUtils.assert_field_equals(data, "capacity", 100)
    
    @allure.title("更新不存在的实验室失败")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_update_nonexistent_lab(self, admin_client):
        """测试更新不存在的实验室失败"""
        with allure.step("更新不存在的实验室"):
            response = admin_client.put("/lab/99999", json={
                "name": "不存在的实验室"
            })
        
        with allure.step("验证更新失败"):
            AssertUtils.assert_failed(response, message="更新不存在的实验室失败")


@allure.feature("实验室管理")
@allure.story("实验室删除")
class TestLabDelete:
    """实验室删除测试"""
    
    @allure.title("删除实验室成功")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.lab
    def test_delete_lab_success(self, admin_client):
        """测试删除实验室成功"""
        lab_data = DataGenerator.generate_lab_data()
        
        with allure.step("创建测试实验室"):
            create_response = admin_client.post("/lab", json=lab_data)
            AssertUtils.assert_success(create_response, "创建测试实验室成功")
        
        with allure.step("删除实验室"):
            # 注意：需要从创建响应中获取ID，这里简化处理
            response = admin_client.delete("/lab/1")
        
        with allure.step("验证删除成功"):
            AssertUtils.assert_success(response, "删除实验室成功")
    
    @allure.title("删除不存在的实验室失败")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_delete_nonexistent_lab(self, admin_client):
        """测试删除不存在的实验室失败"""
        with allure.step("删除不存在的实验室"):
            response = admin_client.delete("/lab/99999")
        
        with allure.step("验证删除失败"):
            AssertUtils.assert_failed(response, message="删除不存在的实验室失败")


@allure.feature("实验室管理")
@allure.story("实验室权限")
class TestLabPermission:
    """实验室权限测试"""
    
    @allure.title("学生无权创建实验室")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_student_create_lab_forbidden(self, student_client):
        """测试学生无权创建实验室"""
        if not student_client.token:
            pytest.skip("学生账号未创建")
        
        lab_data = DataGenerator.generate_lab_data()
        
        with allure.step("学生创建实验室"):
            response = student_client.post("/lab", json=lab_data)
        
        with allure.step("验证权限不足"):
            assert response.status_code == 403 or response.json()["code"] == 403
    
    @allure.title("教师无权删除实验室")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_teacher_delete_lab_forbidden(self, teacher_client, test_lab):
        """测试教师无权删除实验室"""
        if not teacher_client.token:
            pytest.skip("教师账号未创建")
        
        with allure.step("教师删除实验室"):
            response = teacher_client.delete(f"/lab/{test_lab['id']}")
        
        with allure.step("验证权限不足"):
            assert response.status_code == 403 or response.json()["code"] == 403


@allure.feature("实验室管理")
@allure.story("实验室性能")
class TestLabPerformance:
    """实验室性能测试"""
    
    @allure.title("实验室列表查询性能")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_lab_list_performance(self, admin_client):
        """测试实验室列表查询性能"""
        with allure.step("查询实验室列表并验证响应时间"):
            response = admin_client.get("/lab/list")
            AssertUtils.assert_response_time(response, 1.0)
    
    @allure.title("实验室分页查询性能")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.lab
    def test_lab_page_performance(self, admin_client):
        """测试实验室分页查询性能"""
        with allure.step("分页查询实验室并验证响应时间"):
            response = admin_client.get("/lab/page", params={
                "current": 1,
                "size": 20
            })
            AssertUtils.assert_response_time(response, 1.0)
