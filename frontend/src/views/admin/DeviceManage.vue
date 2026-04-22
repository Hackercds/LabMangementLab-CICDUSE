<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <h2>设备管理</h2>
      <el-button type="primary" @click="openDialog('create')">新增设备</el-button>
    </div>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="实验室">
        <el-select v-model="queryForm.labId" placeholder="全部实验室" clearable style="width: 180px;">
          <el-option
            v-for="lab in labList"
            :key="lab.id"
            :label="lab.name"
            :value="lab.id"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="关键词">
        <el-input v-model="queryForm.keyword" placeholder="名称/型号/序列号" clearable style="width: 180px;" />
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable>
          <el-option label="正常" value="NORMAL" />
          <el-option label="借用中" value="BORROWED" />
          <el-option label="维修中" value="MAINTENANCE" />
          <el-option label="已报废" value="SCRAPPED" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="name" label="名称" width="150" />
      <el-table-column prop="model" label="型号" width="120" />
      <el-table-column prop="serialNumber" label="序列号" width="150" />
      <el-table-column prop="labName" label="所属实验室" width="150" />
      <el-table-column prop="purchaseDate" label="购买日期" width="100" />
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="borrowerName" label="借用人" width="100" />
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

    <el-dialog v-model="dialogVisible" :title="dialogType === 'create' ? '新增设备' : '编辑设备'" width="550px">
      <el-form :model="formData" label-width="100px">
        <el-form-item label="设备名称">
          <el-input v-model="formData.name" />
        </el-form-item>
        <el-form-item label="型号">
          <el-input v-model="formData.model" />
        </el-form-item>
        <el-form-item label="序列号">
          <el-input v-model="formData.serialNumber" />
        </el-form-item>
        <el-form-item label="所属实验室">
          <el-select v-model="formData.labId" style="width: 100%;">
            <el-option
              v-for="lab in labList"
              :key="lab.id"
              :label="lab.name"
              :value="lab.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="购买日期">
          <el-date-picker
            v-model="formData.purchaseDate"
            type="date"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="formData.status">
            <el-option label="正常" value="NORMAL" />
            <el-option label="借用中" value="BORROWED" />
            <el-option label="维修中" value="MAINTENANCE" />
            <el-option label="已报废" value="SCRAPPED" />
          </el-select>
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
import { getDevicePage, createDevice, updateDevice, deleteDevice } from '@/api/device'
import { getLabList } from '@/api/lab'
import { ElMessage, ElMessageBox } from 'element-plus'

const statusMap = {
  NORMAL: { text: '正常', type: 'success' },
  BORROWED: { text: '借用中', type: 'warning' },
  MAINTENANCE: { text: '维修中', type: 'info' },
  SCRAPPED: { text: '已报废', type: 'danger' }
}

function getStatusType(status) {
  return statusMap[status]?.type || 'info'
}
function getStatusText(status) {
  return statusMap[status]?.text || status
}

const queryForm = ref({ labId: null, keyword: '', status: null })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const labList = ref([])
const labMap = ref({})
const dialogVisible = ref(false)
const dialogType = ref('create')
const formData = ref({})
const submitting = ref(false)

function resetQuery() {
  queryForm.value = { labId: null, keyword: '', status: null }
  loadData()
}

function openDialog(type, row) {
  dialogType.value = type
  if (type === 'create') {
    formData.value = {
      name: '',
      model: '',
      serialNumber: '',
      labId: null,
      purchaseDate: '',
      status: 'NORMAL',
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
    const res = await getDevicePage({
      current: pagination.value.current,
      size: pagination.value.size,
      labId: queryForm.value.labId,
      status: queryForm.value.status,
      keyword: queryForm.value.keyword
    })
    tableData.value = res.data.records.map(item => ({
      ...item,
      labName: labMap.value[item.labId] || item.labId
    }))
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
      await createDevice(formData.value)
      ElMessage.success('新增成功')
    } else {
      await updateDevice(formData.value.id, formData.value)
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
    await ElMessageBox.confirm(`确定要删除设备 "${row.name}"吗？`, '提示', { type: 'warning' })
    await deleteDevice(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') console.error(e)
  }
}

onMounted(async () => {
  const res = await getLabList()
  labList.value = res.data
  res.data.forEach(lab => {
    labMap.value[lab.id] = lab.name
  })
  loadData()
})
</script>

<style scoped>
</style>
