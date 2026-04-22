"""
预约管理模块测试用例
包含预约申请、审批、查询、取消等测试
"""
import pytest
import allure
from datetime import datetime, timedelta
from conftest import AssertUtils, DataGenerator


@allure.feature("预约管理")
@allure.story("预约申请")
class TestReservationCreate:
    """预约申请测试"""
    
    @allure.title("学生申请预约成功")
    @allure.severity(allure.severity_level.BLOCKER)
    @pytest.mark.smoke
    @pytest.mark.reservation
    def test_student_create_reservation_success(self, student_client, test_lab):
        """测试学生申请预约成功"""
        if not student_client.token:
            pytest.skip("学生账号未创建")
        
        reservation_data = DataGenerator.generate_reservation_data(test_lab["id"])
        
        with allure.step("发送预约申请"):
            response = student_client.post("/reservation", json=reservation_data)
        
        with allure.step("验证预约成功"):
            AssertUtils.assert_success(response, "预约申请成功")
    
    @allure.title("预约时间冲突检测")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_reservation_time_conflict(self, admin_client, test_lab):
        """测试预约时间冲突检测"""
        reservation_data = DataGenerator.generate_reservation_data(test_lab["id"])
        
        with allure.step("创建第一个预约"):
            response1 = admin_client.post("/reservation", json=reservation_data)
            AssertUtils.assert_success(response1, "第一个预约创建成功")
        
        with allure.step("审批第一个预约"):
            data1 = response1.json()
            reservation_id = data1.get("data", {}).get("id")
            if reservation_id:
                admin_client.put(f"/reservation/{reservation_id}/approve", params={
                    "status": "APPROVED",
                    "comment": "审批通过"
                })
        
        with allure.step("创建冲突预约"):
            response2 = admin_client.post("/reservation", json=reservation_data)
            AssertUtils.assert_failed(response2, message="时间冲突检测")
    
    @allure.title("预约必填字段验证")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_reservation_required_fields(self, student_client):
        """测试预约必填字段验证"""
        if not student_client.token:
            pytest.skip("学生账号未创建")
        
        with allure.step("缺少实验室ID"):
            response = student_client.post("/reservation", json={
                "reservationDate": "2026-04-15",
                "startTime": "09:00",
                "endTime": "11:00",
                "purpose": "测试"
            })
            AssertUtils.assert_failed(response, message="缺少实验室ID")
        
        with allure.step("缺少预约日期"):
            response = student_client.post("/reservation", json={
                "labId": 1,
                "startTime": "09:00",
                "endTime": "11:00",
                "purpose": "测试"
            })
            AssertUtils.assert_failed(response, message="缺少预约日期")
    
    @allure.title("预约日期验证-不能预约过去日期")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_reservation_past_date_validation(self, student_client, test_lab):
        """测试不能预约过去日期"""
        if not student_client.token:
            pytest.skip("学生账号未创建")
        
        past_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
        reservation_data = DataGenerator.generate_reservation_data(test_lab["id"], past_date)
        
        with allure.step("预约过去日期"):
            response = student_client.post("/reservation", json=reservation_data)
            AssertUtils.assert_failed(response, message="不能预约过去日期")


@allure.feature("预约管理")
@allure.story("预约审批")
class TestReservationApprove:
    """预约审批测试"""
    
    @allure.title("管理员审批预约通过")
    @allure.severity(allure.severity_level.BLOCKER)
    @pytest.mark.smoke
    @pytest.mark.reservation
    def test_admin_approve_reservation(self, admin_client, pending_reservation):
        """测试管理员审批预约通过"""
        with allure.step("审批预约"):
            response = admin_client.put(
                f"/reservation/{pending_reservation['id']}/approve",
                params={"status": "APPROVED", "comment": "审批通过"}
            )
        
        with allure.step("验证审批成功"):
            AssertUtils.assert_success(response, "审批预约成功")
        
        with allure.step("验证预约状态"):
            detail_response = admin_client.get(f"/reservation/{pending_reservation['id']}")
            data = detail_response.json()["data"]
            AssertUtils.assert_field_equals(data, "status", "APPROVED")
    
    @allure.title("管理员审批预约拒绝")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_admin_reject_reservation(self, admin_client, pending_reservation):
        """测试管理员审批预约拒绝"""
        with allure.step("拒绝预约"):
            response = admin_client.put(
                f"/reservation/{pending_reservation['id']}/approve",
                params={"status": "REJECTED", "comment": "时间冲突"}
            )
        
        with allure.step("验证拒绝成功"):
            AssertUtils.assert_success(response, "拒绝预约成功")
        
        with allure.step("验证预约状态"):
            detail_response = admin_client.get(f"/reservation/{pending_reservation['id']}")
            data = detail_response.json()["data"]
            AssertUtils.assert_field_equals(data, "status", "REJECTED")
    
    @allure.title("教师审批预约")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_teacher_approve_reservation(self, teacher_client, pending_reservation):
        """测试教师审批预约"""
        if not teacher_client.token:
            pytest.skip("教师账号未创建")
        
        with allure.step("审批预约"):
            response = teacher_client.put(
                f"/reservation/{pending_reservation['id']}/approve",
                params={"status": "APPROVED", "comment": "教师审批通过"}
            )
        
        with allure.step("验证审批成功"):
            AssertUtils.assert_success(response, "教师审批成功")
    
    @allure.title("重复审批已处理的预约")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_approve_processed_reservation(self, admin_client, approved_reservation):
        """测试重复审批已处理的预约"""
        with allure.step("重复审批"):
            response = admin_client.put(
                f"/reservation/{approved_reservation['id']}/approve",
                params={"status": "APPROVED", "comment": "重复审批"}
            )
        
        with allure.step("验证审批失败"):
            AssertUtils.assert_failed(response, message="重复审批失败")


@allure.feature("预约管理")
@allure.story("预约查询")
class TestReservationQuery:
    """预约查询测试"""
    
    @allure.title("查询我的预约列表")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.smoke
    @pytest.mark.reservation
    def test_query_my_reservations(self, admin_client):
        """测试查询我的预约列表"""
        with allure.step("查询我的预约"):
            response = admin_client.get("/reservation/my", params={
                "current": 1,
                "size": 10
            })
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "查询我的预约成功")
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "records")
            AssertUtils.assert_field_exists(data, "total")
    
    @allure.title("管理端分页查询预约")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_admin_query_reservations(self, admin_client):
        """测试管理端分页查询预约"""
        with allure.step("查询预约列表"):
            response = admin_client.get("/reservation/list", params={
                "current": 1,
                "size": 10
            })
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "管理端查询预约成功")
            data = response.json()["data"]
            AssertUtils.assert_field_exists(data, "records")
            AssertUtils.assert_field_exists(data, "total")
    
    @allure.title("按状态筛选预约")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_filter_reservations_by_status(self, admin_client):
        """测试按状态筛选预约"""
        with allure.step("查询待审批预约"):
            response = admin_client.get("/reservation/list", params={
                "current": 1,
                "size": 10,
                "status": "PENDING"
            })
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "按状态筛选成功")
    
    @allure.title("查询已占用时间段")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_query_busy_times(self, admin_client, test_lab):
        """测试查询已占用时间段"""
        date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        with allure.step("查询已占用时间段"):
            response = admin_client.get("/reservation/busy", params={
                "labId": test_lab["id"],
                "date": date
            })
        
        with allure.step("验证查询成功"):
            AssertUtils.assert_success(response, "查询已占用时间段成功")


@allure.feature("预约管理")
@allure.story("预约取消")
class TestReservationCancel:
    """预约取消测试"""
    
    @allure.title("用户取消待审批预约")
    @allure.severity(allure.severity_level.CRITICAL)
    @pytest.mark.reservation
    def test_cancel_pending_reservation(self, admin_client, pending_reservation):
        """测试用户取消待审批预约"""
        with allure.step("取消预约"):
            response = admin_client.put(f"/reservation/{pending_reservation['id']}/cancel")
        
        with allure.step("验证取消成功"):
            AssertUtils.assert_success(response, "取消预约成功")
        
        with allure.step("验证预约状态"):
            detail_response = admin_client.get(f"/reservation/{pending_reservation['id']}")
            data = detail_response.json()["data"]
            AssertUtils.assert_field_equals(data, "status", "CANCELED")
    
    @allure.title("取消已审批预约失败")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_cancel_approved_reservation(self, admin_client, approved_reservation):
        """测试取消已审批预约失败"""
        with allure.step("取消预约"):
            response = admin_client.put(f"/reservation/{approved_reservation['id']}/cancel")
        
        with allure.step("验证取消失败"):
            AssertUtils.assert_failed(response, message="取消已审批预约失败")


@allure.feature("预约管理")
@allure.story("预约性能")
class TestReservationPerformance:
    """预约性能测试"""
    
    @allure.title("预约列表查询性能")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    def test_reservation_list_performance(self, admin_client):
        """测试预约列表查询性能"""
        with allure.step("查询预约列表并验证响应时间"):
            response = admin_client.get("/reservation/list", params={
                "current": 1,
                "size": 20
            })
            AssertUtils.assert_response_time(response, 1.0)
    
    @allure.title("并发预约申请")
    @allure.severity(allure.severity_level.NORMAL)
    @pytest.mark.reservation
    @pytest.mark.skip(reason="需要并发测试环境")
    def test_concurrent_reservation(self):
        """测试并发预约申请"""
        pass
