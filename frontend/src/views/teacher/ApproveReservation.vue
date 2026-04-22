<template>
  <div>
    <h2>预约审批</h2>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="编号" width="60" />
      <el-table-column prop="username" label="预约人" width="100" />
      <el-table-column prop="labName" label="实验室" width="150" />
      <el-table-column prop="reservationDate" label="日期" width="100" />
      <el-table-column prop="startTime" label="开始时间" width="90" />
      <el-table-column prop="endTime" label="结束时间" width="90" />
      <el-table-column prop="purpose" label="事由" min-width="150" />
      <el-table-column prop="participantCount" label="人数" width="60" />
      <el-table-column prop="createTime" label="申请时间" width="170" />
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button type="success" size="small" @click="openApproveDialog(row, 'APPROVED')">
            通过
          </el-button>
          <el-button type="danger" size="small" @click="openApproveDialog(row, 'REJECTED')">
            拒绝
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

    <!-- 审批对话框 -->
    <el-dialog v-model="approveDialogVisible" title="审批预约">
      <el-form :model="approveForm" label-width="100px">
        <el-form-item label="预约信息">
          <div>
            <p>{{ approveInfo.labName }} - {{ approveInfo.reservationDate }} {{ approveInfo.startTime }}-{{ approveInfo.endTime }}</p>
            <p>预约人：{{ approveInfo.username }}</p>
            <p>事由：{{ approveInfo.purpose }}</p>
          </div>
        </el-form-item>
        <el-form-item label="审批意见">
          <el-input v-model="approveForm.comment" type="textarea" placeholder="请输入审批意见（可选）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="approveDialogVisible = false">取消</el-button>
        <el-button :type="approveForm.status === 'APPROVED' ? 'success' : 'danger'" @click="handleApprove" :loading="approving">
          {{ approveForm.status === 'APPROVED' ? '通过' : '拒绝' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getReservationList, approveReservation } from '@/api/reservation'
import { getLabList } from '@/api/lab'
import { ElMessage } from 'element-plus'

const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const labMap = ref({})
const userMap = ref({})
const approveDialogVisible = ref(false)
const approveForm = ref({ id: null, status: null, comment: '' })
const approveInfo = ref({})
const approving = ref(false)

async function loadData() {
  loading.value = true
  try {
    const res = await getReservationList({
      current: pagination.value.current,
      size: pagination.value.size,
      labId: null,
      userId: null,
      status: 'PENDING'
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

function openApproveDialog(row, status) {
  approveForm.value = {
    id: row.id,
    status,
    comment: ''
  }
  approveInfo.value = {
    labName: row.labName,
    reservationDate: row.reservationDate,
    startTime: row.startTime,
    endTime: row.endTime,
    username: row.username,
    purpose: row.purpose
  }
  approveDialogVisible.value = true
}

async function handleApprove() {
  try {
    approving.value = true
    await approveReservation(approveForm.value.id, approveForm.value.status, approveForm.value.comment)
    ElMessage.success(approveForm.value.status === 'APPROVED' ? '审批通过' : '已拒绝')
    approveDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error(e)
  } finally {
    approving.value = false
  }
}

onMounted(async () => {
  const res = await getLabList()
  res.data.forEach(lab => {
    labMap.value[lab.id] = lab.name
  })
  await loadData()
})
</script>

<style scoped>
</style>
