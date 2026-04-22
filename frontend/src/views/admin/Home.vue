<template>
  <div class="main-layout">
    <div class="sidebar">
      <div class="logo">实验室管理系统</div>
      <el-menu
        :default-active="$route.path"
        class="el-menu-vertical-demo"
        background-color="#304156"
        text-color="#fff"
        active-text-color="#409eff"
        router
      >
        <el-menu-item index="/admin/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>仪表盘</span>
        </el-menu-item>
        <el-menu-item index="/admin/user">
          <el-icon><User /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/lab">
          <el-icon><OfficeBuilding /></el-icon>
          <span>实验室管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/device">
          <el-icon><Monitor /></el-icon>
          <span>设备管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/reservation">
          <el-icon><Calendar /></el-icon>
          <span>预约管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/consumable">
          <el-icon><Box /></el-icon>
          <span>耗材管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/statistics">
          <el-icon><DataLine /></el-icon>
          <span>数据统计</span>
        </el-menu-item>
        <el-menu-item index="/admin/announcement">
          <el-icon><Bell /></el-icon>
          <span>公告管理</span>
        </el-menu-item>
        <el-menu-item index="/admin/log">
          <el-icon><List /></el-icon>
          <span>操作日志</span>
        </el-menu-item>
      </el-menu>
    </div>
    <div class="main-content">
      <div class="content-header">
        <span>欢迎，{{ userInfo?.realName }}</span>
        <el-button type="text" @click="handleLogout" style="margin-left: 20px;">退出登录</el-button>
      </div>
      <div class="content-body">
        <div class="card">
          <router-view />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  Odometer, User, OfficeBuilding, Monitor,
  Calendar, Box, DataLine, Bell, List
} from '@element-plus/icons-vue'
import { useUserStore } from '@/store'
import { useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'

const userStore = useUserStore()
const router = useRouter()
const userInfo = userStore.userInfo

function handleLogout() {
  ElMessageBox.confirm('确定要退出登录吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    userStore.logout()
    router.push('/login')
  })
}
</script>

<style scoped>
.main-layout {
  display: flex;
  height: 100vh;
  overflow: hidden;
}

.sidebar {
  width: 240px;
  background: #304156;
  color: white;
  display: flex;
  flex-direction: column;
}

.logo {
  height: 60px;
  line-height: 60px;
  text-align: center;
  font-size: 18px;
  font-weight: bold;
  background: #1f2d3d;
  color: #409eff;
}

.el-menu-vertical-demo {
  border-right: none;
  flex: 1;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #f5f7fa;
  overflow: hidden;
}

.content-header {
  height: 60px;
  background: white;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 0 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.content-body {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
}

.card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  padding: 24px;
  min-height: calc(100% - 40px);
}

.el-menu-item {
  height: 60px;
  line-height: 60px;
  margin: 0;
}

.el-menu-item.is-active {
  background-color: rgba(64, 158, 255, 0.2) !important;
}

.el-menu-item:hover {
  background-color: rgba(255, 255, 255, 0.1) !important;
}
</style>
