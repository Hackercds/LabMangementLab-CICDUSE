<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <h2>用户管理</h2>
      <el-button type="primary" @click="openDialog('create')">新增用户</el-button>
    </div>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="关键词">
        <el-input v-model="queryForm.keyword" placeholder="用户名/姓名" clearable style="width: 200px;" />
      </el-form-item>
      <el-form-item label="角色">
        <el-select v-model="queryForm.role" placeholder="全部角色" clearable style="width: 120px;">
          <el-option label="学生" value="STUDENT" />
          <el-option label="教师" value="TEACHER" />
          <el-option label="管理员" value="ADMIN" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable style="width: 120px;">
          <el-option label="启用" value="ENABLED" />
          <el-option label="禁用" value="DISABLED" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="username" label="账号" width="120" />
      <el-table-column prop="realName" label="姓名" width="120" />
      <el-table-column prop="role" label="角色" width="100">
        <template #default="{ row }">
          <el-tag>{{ getRoleText(row.role) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="phone" label="电话" width="120" />
      <el-table-column prop="email" label="邮箱" width="180" />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 'ENABLED' ? 'success' : 'danger'">
            {{ row.status === 'ENABLED' ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createTime" label="注册时间" width="170" />
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button size="small" @click="openDialog('edit', row)">编辑</el-button>
          <el-button
            size="small"
            :type="row.status === 'ENABLED' ? 'warning' : 'success'"
            @click="handleChangeStatus(row)">
            {{ row.status === 'ENABLED' ? '禁用' : '启用' }}
          </el-button>
          <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div style="margin-top: 20px;">
      <el-pagination
        v-model:current-page="pagination.current"
        v-model:page-size="pagination.size"
        @size-change="loadData"
        @current-change="loadData"
        layout="total, size, prev, pager, next, jumper"
        :total="total"
      />
    </div>

    <!-- 新增编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogType === 'create' ? '新增用户' : '编辑用户'"
      width="500px"
    >
      <el-form :model="formData" label-width="100px">
        <el-form-item label="账号" :required="dialogType === 'create'">
          <el-input v-model="formData.username" :disabled="dialogType === 'edit'" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="formData.password" type="password" placeholder="新增用户必填，不修改留空" />
        </el-form-item>
        <el-form-item label="真实姓名">
          <el-input v-model="formData.realName" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="formData.role">
            <el-option label="学生" value="STUDENT" />
            <el-option label="教师" value="TEACHER" />
            <el-option label="管理员" value="ADMIN" />
          </el-select>
        </el-form-item>
        <el-form-item label="电话">
          <el-input v-model="formData.phone" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="formData.email" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          提交
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getUserPage, createUser, updateUser, deleteUser, changeUserStatus } from '@/api/user'
import { ElMessage, ElMessageBox } from 'element-plus'

const roleMap = {
  STUDENT: '学生',
  TEACHER: '教师',
  ADMIN: '管理员'
}

function getRoleText(role) {
  return roleMap[role] || role
}

const queryForm = ref({ keyword: '', role: null, status: null })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const dialogVisible = ref(false)
const dialogType = ref('create')
const formData = ref({})
const submitting = ref(false)

function resetQuery() {
  queryForm.value = { keyword: '', role: null, status: null }
  loadData()
}

function openDialog(type, row) {
  dialogType.value = type
  if (type === 'create') {
    formData.value = {
      username: '',
      password: '',
      realName: '',
      role: 'STUDENT',
      phone: '',
      email: '',
      status: 'ENABLED'
    }
  } else {
    formData.value = { ...row }
  }
  dialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getUserPage({
      current: pagination.value.current,
      size: pagination.value.size,
      keyword: queryForm.value.keyword,
      role: queryForm.value.role,
      status: queryForm.value.status
    })
    tableData.value = res.data.records
    total.value = res.data.total
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  try {
    submitting.value = true
    if (dialogType.value === 'create') {
      if (!formData.value.username || !formData.value.password) {
        ElMessage.warning('请填写完整信息')
        return
      }
      await createUser(formData.value)
      ElMessage.success('新增成功')
    } else {
      await updateUser(formData.value.id, formData.value)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    console.error(e)
  } finally {
    submitting.value = false
  }
}

async function handleChangeStatus(row) {
  const newStatus = row.status === 'ENABLED' ? 'DISABLED' : 'ENABLED'
  try {
    await ElMessageBox.confirm(`确定要${newStatus === 'ENABLED' ? '启用' : '禁用'}用户"${row.username}"吗？`, '提示')
    await changeUserStatus(row.id, newStatus)
    ElMessage.success('修改成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') console.error(e)
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定要删除用户"${row.username}"吗？此操作不可恢复`, '提示', { type: 'warning' })
    await deleteUser(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') console.error(e)
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
</style>
