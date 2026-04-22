<template>
  <div>
    <h2>设备查询</h2>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="实验室">
        <el-select v-model="queryForm.labId" placeholder="全部实验室" clearable style="width: 200px;">
          <el-option
            v-for="lab in labList"
            :key="lab.id"
            :label="lab.name"
            :value="lab.id"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable style="width: 150px;">
          <el-option label="正常可用" value="NORMAL" />
          <el-option label="借用中" value="BORROWED" />
          <el-option label="维修中" value="MAINTENANCE" />
          <el-option label="已报废" value="SCRAPPED" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="queryForm = { labId: null, status: null }">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="name" label="设备名称" width="150" />
      <el-table-column prop="model" label="型号" width="120" />
      <el-table-column prop="serialNumber" label="序列号" width="150" />
      <el-table-column prop="labName" label="所属实验室" width="150" />
      <el-table-column prop="purchaseDate" label="购买日期" width="120" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150">
        <template #default="{ row }">
          <el-button type="primary" size="small" @click="openBorrowDialog(row)"
            :disabled="row.status !== 'NORMAL'">
            申请借用
          </el-button>
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

    <!-- 借用对话框 -->
    <el-dialog v-model="borrowDialogVisible" title="申请借用设备">
      <el-form :model="borrowForm" label-width="100px">
        <el-form-item label="设备名称">
          <el-input :model-value="currentDevice?.name" disabled />
        </el-form-item>
        <el-form-item label="预计归还时间">
          <el-date-picker
            v-model="borrowForm.expectReturnTime"
            type="date"
            placeholder="选择预计归还日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="borrowDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleBorrow" :loading="borrowing">提交借用申请</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getDeviceList, borrowDevice } from '@/api/device'
import { getLabList } from '@/api/lab'
import { ElMessage } from 'element-plus'

const queryForm = ref({
  labId: null,
  status: null
})
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const labList = ref([])
const labMap = ref({})
const borrowDialogVisible = ref(false)
const currentDevice = ref(null)
const borrowForm = ref({ expectReturnTime: null })
const borrowing = ref(false)

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

function openBorrowDialog(device) {
  currentDevice.value = device
  borrowForm.value = { expectReturnTime: null }
  borrowDialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getDeviceList(queryForm.value.labId, queryForm.value.status)
    tableData.value = res.data.map(item => ({
      ...item,
      labName: labMap.value[item.labId] || item.labId
    }))
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function handleBorrow() {
  if (!borrowForm.value.expectReturnTime) {
    ElMessage.warning('请选择预计归还时间')
    return
  }
  try {
    borrowing.value = true
    await borrowDevice(currentDevice.value.id, {
      expectReturnTime: borrowForm.value.expectReturnTime
    })
    ElMessage.success('借用成功')
    borrowDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error(e)
  } finally {
    borrowing.value = false
  }
}

onMounted(async () => {
  const labs = await getLabList()
  labList.value = labs.data
  labs.data.forEach(lab => {
    labMap.value[lab.id] = lab.name
  })
  await loadData()
})
</script>

<style scoped>
</style>
