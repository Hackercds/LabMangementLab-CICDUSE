<template>
  <div>
    <h2>预约管理</h2>
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
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable>
          <el-option label="待审批" value="PENDING" />
          <el-option label="已通过" value="APPROVED" />
          <el-option label="已拒绝" value="REJECTED" />
          <el-option label="已取消" value="CANCELED" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="编号" width="60" />
      <el-table-column prop="username" label="预约人" width="100" />
      <el-table-column prop="labName" label="实验室" width="150" />
      <el-table-column prop="reservationDate" label="日期" width="100" />
      <el-table-column prop="startTime" label="开始" width="70" />
      <el-table-column prop="endTime" label="结束" width="70" />
      <el-table-column prop="purpose" label="事由" min-width="120" />
      <el-table-column prop="participantCount" label="人数" width="60" />
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="approverName" label="审批人" width="100" />
      <el-table-column label="操作" width="150">
        <template #default="{ row }">
          <template v-if="row.status === 'PENDING'">
            <el-button type="success" size="small" @click="handleApprove(row, 'APPROVED')">通过</el-button>
            <el-button type="danger" size="small" @click="handleApprove(row, 'REJECTED')">拒绝</el-button>
          </template>
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
import { getReservationList, approveReservation, forceApproveReservation } from '@/api/reservation'
import { getLabList } from '@/api/lab'
import { ElMessage, ElMessageBox } from 'element-plus'

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

const queryForm = ref({ labId: null, status: null })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const labList = ref([])
const labMap = ref({})

function resetQuery() {
  queryForm.value = { labId: null, status: null }
  loadData()
}

async function loadData() {
  loading.value = true
  try {
    const res = await getReservationList({
      current: pagination.value.current,
      size: pagination.value.size,
      labId: queryForm.value.labId,
      userId: null,
      status: queryForm.value.status
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

const handleApprove = async (row, status) => {
  loading.value = true
  try {
    await approveReservation(row.id, status, '')
    ElMessage.success(status === 'APPROVED' ? '审批通过' : '已拒绝')
    loadData()
  } catch (error) {
    // 处理409冲突错误
    if (error.response && error.response.status === 409) {
      const conflicts = error.response.data?.data || []
      try {
        await ElMessageBox.confirm(
          `该时间段与以下 ${conflicts.length} 个预约冲突：\n\n` +
          conflicts.map(c => `预约ID: ${c.id}, 日期: ${c.reservationDate}, 时间: ${c.startTime}-${c.endTime}`).join('\n') +
          '\n\n是否强制审批？强制审批将自动拒绝冲突的预约。',
          '时间冲突',
          {
            confirmButtonText: '强制审批',
            cancelButtonText: '取消',
            type: 'warning'
          }
        )
        // 用户选择强制审批
        await forceApproveReservation(row.id, '')
        ElMessage.success('强制审批成功，已自动拒绝冲突预约')
        loadData()
      } catch {
        // 用户取消操作
      }
    } else {
      ElMessage.error('审批失败')
    }
  } finally {
    loading.value = false
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
