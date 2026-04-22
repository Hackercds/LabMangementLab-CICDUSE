<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <h1>实验室管理系统</h1>
        <p>欢迎使用实验室管理系统</p>
      </div>
      <el-form :model="form" label-width="80px" class="login-form">
        <el-form-item label="账号" prop="username">
          <el-input v-model="form.username" placeholder="请输入学号/工号" prefix-icon="el-icon-user" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" placeholder="请输入密码" prefix-icon="el-icon-lock" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleLogin" :loading="loading" style="width: 100%;">
            登录
          </el-button>
        </el-form-item>
        <div style="text-align: center; margin-top: 15px;">
          <el-link type="primary" @click="goRegister">还没有账号？去注册</el-link>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store'
import { login } from '@/api/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()
const form = ref({
  username: '',
  password: ''
})
const loading = ref(false)

async function handleLogin() {
  if (!form.value.username || !form.value.password) {
    ElMessage.warning('请输入账号和密码')
    return
  }
  loading.value = true
  try {
    const res = await login(form.value)
    userStore.setAuth(res.data)
    ElMessage.success('登录成功')
    const role = res.data.role
    if (role === 'ADMIN') {
      router.push('/admin/dashboard')
    } else if (role === 'TEACHER') {
      router.push('/teacher/home')
    } else {
      router.push('/student/home')
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

function goRegister() {
  router.push('/register')
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-box {
  background: white;
  border-radius: 10px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  padding: 30px;
  width: 400px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h1 {
  color: #303133;
  font-size: 24px;
  margin-bottom: 10px;
}

.login-header p {
  color: #909399;
  font-size: 14px;
}

.login-form {
  margin-top: 20px;
}

.el-form-item {
  margin-bottom: 20px;
}

.el-button {
  height: 40px;
  font-size: 16px;
}
</style>
