<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <h2>实验室管理</h2>
      <el-button type="primary" @click="openDialog('create')">新增实验室</el-button>
    </div>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="关键词">
        <el-input v-model="queryForm.keyword" placeholder="名称/位置" clearable style="width: 200px;" />
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable>
          <el-option label="空闲" value="FREE" />
          <el-option label="占用" value="OCCUPIED" />
          <el-option label="维修" value="MAINTENANCE" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="name" label="名称" width="180" />
      <el-table-column prop="location" label="位置" width="150" />
      <el-table-column prop="capacity" label="容纳人数" width="90" />
      <el-table-column prop="deviceCount" label="设备数" width="80" />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="director" label="负责人" width="100" />
      <el-table-column label="操作" width="180">
        <template #default="{ row }">
          <el-button size="small" @click="openDialog('edit', row)">编辑</el-button>
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

    <el-dialog v-model="dialogVisible" :title="dialogType === 'create' ? '新增实验室' : '编辑实验室'" width="500px">
      <el-form :model="formData" label-width="100px">
        <el-form-item label="实验室名称">
          <el-input v-model="formData.name" />
        </el-form-item>
        <el-form-item label="位置">
          <el-input v-model="formData.location" />
        </el-form-item>
        <el-form-item label="容纳人数">
          <el-input-number v-model="formData.capacity" :min="1" />
        </el-form-item>
        <el-form-item label="设备数量">
          <el-input-number v-model="formData.deviceCount" :min="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="formData.status">
            <el-option label="空闲" value="FREE" />
            <el-option label="占用" value="OCCUPIED" />
            <el-option label="维修" value="MAINTENANCE" />
          </el-select>
        </el-form-item>
        <el-form-item label="负责人">
          <el-input v-model="formData.director" />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="formData.phone" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getLabPage, createLab, updateLab, deleteLab } from '@/api/lab'
import { ElMessage, ElMessageBox } from 'element-plus'

const statusMap = {
  FREE: { text: '空闲', type: 'success' },
  OCCUPIED: { text: '占用', type: 'warning' },
  MAINTENANCE: { text: '维修', type: 'info' }
}

function getStatusType(status) {
  return statusMap[status]?.type || 'info'
}
function getStatusText(status) {
  return statusMap[status]?.text || status
}

const queryForm = ref({ keyword: '', status: null })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const dialogVisible = ref(false)
const dialogType = ref('create')
const formData = ref({})
const submitting = ref(false)

function resetQuery() {
  queryForm.value = { keyword: '', status: null }
  loadData()
}

function openDialog(type, row) {
  dialogType.value = type
  if (type === 'create') {
    formData.value = {
      name: '',
      location: '',
      capacity: 30,
      deviceCount: 0,
      status: 'FREE',
      director: '',
      phone: '',
      remark: ''
    }
  } else {
    formData.value = { ...row }
  }
  dialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getLabPage({
      current: pagination.value.current,
      size: pagination.value.size,
      keyword: queryForm.value.keyword,
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
      await createLab(formData.value)
      ElMessage.success('新增成功')
    } else {
      await updateLab(formData.value.id, formData.value)
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

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定要删除实验室 "${row.name}"吗？`, '提示', { type: 'warning' })
    await deleteLab(row.id)
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
