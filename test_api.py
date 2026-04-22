import requests
import json

# 后端API地址
BASE_URL = "http://localhost:8081/api"

def test_login():
    """测试登录功能"""
    url = f"{BASE_URL}/auth/login"
    data = {
        "username": "admin",
        "password": "admin123"
    }
    response = requests.post(url, json=data)
    print(f"登录响应: {response.status_code}")
    print(f"登录数据: {response.json()}")
    if response.status_code == 200:
        return response.json().get("data", {}).get("token")
    return None

def test_create_reservation(token):
    """测试创建预约"""
    url = f"{BASE_URL}/reservation"
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "labId": 1,
        "reservationDate": "2026-04-15",
        "startTime": "09:00",
        "endTime": "11:00",
        "purpose": "测试预约",
        "participantCount": 10
    }
    response = requests.post(url, json=data, headers=headers)
    print(f"\n创建预约响应: {response.status_code}")
    print(f"创建预约数据: {response.json()}")
    return response.status_code == 200

def test_get_reservations(token):
    """测试获取预约列表"""
    url = f"{BASE_URL}/reservation/list?current=1&size=10"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    print(f"\n获取预约列表响应: {response.status_code}")
    print(f"获取预约列表数据: {response.json()}")
    if response.status_code == 200:
        records = response.json().get("data", {}).get("records", [])
        if records:
            return records[0].get("id")
    return None

def test_approve_reservation(token, reservation_id):
    """测试审批预约"""
    url = f"{BASE_URL}/reservation/{reservation_id}/approve"
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "status": "APPROVED",
        "comment": "测试审批"
    }
    response = requests.put(url, params=params, headers=headers)
    print(f"\n审批预约响应: {response.status_code}")
    print(f"审批预约数据: {response.text}")
    return response.status_code == 200

if __name__ == "__main__":
    print("=== 开始测试预约审批功能 ===")
    
    # 1. 登录
    token = test_login()
    if not token:
        print("登录失败！")
        exit(1)
    print(f"\n获取到token: {token[:20]}...")
    
    # 2. 创建预约
    if not test_create_reservation(token):
        print("创建预约失败！")
    
    # 3. 获取预约列表
    reservation_id = test_get_reservations(token)
    if not reservation_id:
        print("获取预约列表失败！")
        exit(1)
    print(f"\n获取到预约ID: {reservation_id}")
    
    # 4. 审批预约
    if test_approve_reservation(token, reservation_id):
        print("\n=== 测试成功 ===")
    else:
        print("\n=== 测试失败 ===")
