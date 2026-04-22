<template>
  <div>
    <h2>我的预约</h2>
    <el-table :data="tableData" border loading="loading">
      <el-table-column prop="id" label="编号" width="80" />
      <el-table-column prop="labName" label="实验室" width="150" />
      <el-table-column prop="reservationDate" label="日期" width="120" />
      <el-table-column prop="startTime" label="开始时间" width="100" />
      <el-table-column prop="endTime" label="结束时间" width="100" />
      <el-table-column prop="purpose" label="事由" min-width="150" />
      <el-table-column prop="participantCount" label="人数" width="80" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="120">
        <template #default="{ row }">
          <el-button type="danger" size="small" @click="handleCancel(row)"
            :disabled="row.status !== 'PENDING'">
            取消
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getMyReservation, cancelReservation } from '@/api/reservation'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getLabList } from '@/api/lab'

const tableData = ref([])
const loading = ref(false)
const pagination = ref({
  current: 1,
  size: 10
})
const total = ref(0)
const labMap = ref({})

const statusMap = {
  PENDING: { text: '待审批', type: 'warning' },
  APPROVED: { text: '已通过', type: 'success' },
  REJECTED: { text: '已拒绝', type: 'danger' },
  CANCELED: { text: '已取消', type: 'info' }
}

function getStatusType(status) {
  return statusMap[status]?.type || 'info'
}

function getStatusText(status) {
  return statusMap[status]?.text || status
}

async function loadData() {
  loading.value = true
  try {
    const res = await getMyReservation({
      current: pagination.value.current,
      size: pagination.value.size
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

async function handleCancel(row) {
  try {
    await ElMessageBox.confirm('确定要取消这个预约吗？', '提示')
    await cancelReservation(row.id)
    ElMessage.success('取消成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') {
      console.error(e)
    }
  }
}

onMounted(async () => {
  // 加载实验室名称映射
  const res = await getLabList()
  res.data.forEach(lab => {
    labMap.value[lab.id] = lab.name
  })
  await loadData()
})
</script>

<style scoped>
</style>
