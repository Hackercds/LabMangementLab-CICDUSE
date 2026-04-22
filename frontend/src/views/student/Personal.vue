<template>
  <div>
    <h2>个人中心</h2>
    <el-card style="max-width: 500px;">
      <el-form :model="userInfo" label-width="100px">
        <el-form-item label="账号">
          <el-input v-model="userInfo.username" disabled />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="userInfo.realName" />
        </el-form-item>
        <el-form-item label="角色">
          <el-input v-model="roleText" disabled />
        </el-form-item>
        <el-form-item label="电话">
          <el-input v-model="userInfo.phone" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="userInfo.email" />
        </el-form-item>
      </el-form>
    </el-card>

    <el-card title="修改密码" style="max-width: 500px; margin-top: 20px;">
      <el-form :model="passwordForm" label-width="100px">
        <el-form-item label="旧密码">
          <el-input v-model="passwordForm.oldPassword" type="password" />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="passwordForm.newPassword" type="password" />
        </el-form-item>
        <el-form-item label="确认密码">
          <el-input v-model="passwordForm.confirmPassword" type="password" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleChangePassword" :loading="changing">修改密码</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useUserStore } from '@/store'
import { changePassword } from '@/api/auth'
import { ElMessage } from 'element-plus'

const userStore = useUserStore()
const userInfo = ref({ ...userStore.userInfo })
const passwordForm = ref({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})
const changing = ref(false)

const roleMap = {
  STUDENT: '学生',
  TEACHER: '教师',
  ADMIN: '管理员'
}

const roleText = computed(() => {
  return roleMap[userStore.userInfo.role] || userStore.userInfo.role
})

async function handleChangePassword() {
  if (!passwordForm.value.oldPassword || !passwordForm.value.newPassword) {
    ElMessage.warning('请填写完整信息')
    return
  }
  if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
    ElMessage.warning('两次密码不一致')
    return
  }
  try {
    changing.value = true
    await changePassword({
      oldPassword: passwordForm.value.oldPassword,
      newPassword: passwordForm.value.newPassword
    })
    ElMessage.success('密码修改成功，请重新登录')
    userStore.logout()
    window.location.href = '/#/login'
  } catch (e) {
    console.error(e)
  } finally {
    changing.value = false
  }
}
</script>

<style scoped>
</style>
