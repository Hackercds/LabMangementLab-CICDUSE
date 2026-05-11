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
        <el-menu-item index="/teacher/reservation">
          <el-icon><Calendar /></el-icon>
          <span>预约实验室</span>
        </el-menu-item>
        <el-menu-item index="/teacher/my-reservation">
          <el-icon><Document /></el-icon>
          <span>我的预约</span>
        </el-menu-item>
        <el-menu-item index="/teacher/approve">
          <el-icon><Checked /></el-icon>
          <span>预约审批</span>
        </el-menu-item>
        <el-menu-item index="/teacher/device">
          <el-icon><Monitor /></el-icon>
          <span>设备查询</span>
        </el-menu-item>
        <el-menu-item index="/teacher/consumable">
          <el-icon><Box /></el-icon>
          <span>耗材领用</span>
        </el-menu-item>
        <el-menu-item index="/teacher/personal">
          <el-icon><User /></el-icon>
          <span>个人中心</span>
        </el-menu-item>
      </el-menu>
    </div>
    <div class="main-content">
      <div class="content-header">
        <span>欢迎，{{ userInfo?.realName }}</span>
        <el-popover placement="bottom" :width="300" trigger="click">
          <template #reference>
            <el-badge :value="notifyCount" :hidden="notifyCount===0" style="margin:0 20px;cursor:pointer">
              <el-icon :size="20"><Bell /></el-icon>
            </el-badge>
          </template>
          <div v-if="notifications.length===0" style="color:#999;text-align:center">暂无通知</div>
          <div v-for="n in notifications" :key="n.id" style="padding:8px 0;border-bottom:1px solid #eee">
            <div style="font-weight:bold;font-size:13px">{{ n.title }}</div>
            <div style="font-size:12px;color:#666">{{ n.content }}</div>
            <div style="font-size:11px;color:#999">{{ n.publishTime }}</div>
          </div>
        </el-popover>
        <el-button type="text" @click="handleLogout">退出登录</el-button>
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
import { Calendar, Document, Checked, Box, User, Monitor, Bell } from '@element-plus/icons-vue'
import { useUserStore } from '@/store'
import { useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { ref, onMounted, onUnmounted } from 'vue'
import request from '@/api/request'
import { getToken } from '@/utils/auth'

const userStore = useUserStore()
const router = useRouter()
const userInfo = userStore.userInfo

const notifyCount = ref(0)
const notifications = ref([])
const notificationTimer = ref(null)
async function loadNotifications() { if (!getToken()) return; try { const [c, l] = await Promise.all([request({url:'/announcement/unread-count',method:'get'}),request({url:'/announcement/my-notifications',method:'get'})]); notifyCount.value = c.data||0; notifications.value = l.data||[] } catch {} }
onMounted(() => { if (getToken()) { loadNotifications(); notificationTimer.value = setInterval(loadNotifications, 30000) } })
onUnmounted(() => { if (notificationTimer.value) clearInterval(notificationTimer.value) })

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
