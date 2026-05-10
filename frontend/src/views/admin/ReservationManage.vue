<template>
  <div>
    <h2>预约管理</h2>

    <el-tabs v-model="activeTab" @tab-change="onTabChange">
      <!-- Tab 1: 预约列表 -->
      <el-tab-pane label="预约列表" name="list">
        <el-form :inline="true" :model="queryForm">
          <el-form-item label="实验室">
            <el-select v-model="queryForm.labId" placeholder="全部" clearable style="width:180px">
              <el-option v-for="lab in labList" :key="lab.id" :label="lab.name" :value="lab.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="queryForm.status" placeholder="全部" clearable>
              <el-option label="待审批" value="PENDING" />
              <el-option label="已通过" value="APPROVED" />
              <el-option label="已拒绝" value="REJECTED" />
              <el-option label="已取消" value="CANCELED" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button @click="loadData" type="primary">查询</el-button>
            <el-button @click="resetQuery">重置</el-button>
            <el-button type="success" @click="showCreateDialog">代申请</el-button>
            <el-button @click="showBatchDialog">批量导入</el-button>
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
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="220">
            <template #default="{ row }">
              <template v-if="row.status === 'PENDING'">
                <el-button type="success" size="small" @click="handleApprove(row, 'APPROVED')">通过</el-button>
                <el-button type="danger" size="small" @click="handleApprove(row, 'REJECTED')">拒绝</el-button>
              </template>
              <el-button v-if="row.status !== 'CANCELED'" type="warning" size="small" @click="handleAdminCancel(row)">撤销</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination style="margin-top:20px" v-model:current-page="pagination.current" v-model:page-size="pagination.size"
          @size-change="loadData" @current-change="loadData" layout="total,size,prev,pager,next,jumper" :total="total" />
      </el-tab-pane>

      <!-- Tab 2: 日历预览 -->
      <el-tab-pane label="日历预览" name="overview">
        <el-form :inline="true">
          <el-form-item label="日期">
            <el-date-picker v-model="overviewDate" type="date" format="YYYY-MM-DD" value-format="YYYY-MM-DD" @change="loadOverview" />
          </el-form-item>
        </el-form>
        <el-table :data="overviewData" border v-loading="overviewLoading" empty-text="该日暂无预约">
          <el-table-column prop="labName" label="实验室" width="200" />
          <el-table-column prop="startTime" label="开始" width="100" />
          <el-table-column prop="endTime" label="结束" width="100" />
          <el-table-column prop="purpose" label="事由" min-width="150" />
          <el-table-column prop="username" label="预约人" width="100" />
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- 代申请对话框 -->
    <el-dialog v-model="createDialogVisible" title="代他人申请" width="500px">
      <el-form :model="createForm" label-width="100px">
        <el-form-item label="用户ID"><el-input-number v-model="createForm.userId" :min="1" /></el-form-item>
        <el-form-item label="实验室">
          <el-select v-model="createForm.labId" placeholder="选择实验室">
            <el-option v-for="lab in labList" :key="lab.id" :label="lab.name" :value="lab.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期"><el-date-picker v-model="createForm.date" type="date" format="YYYY-MM-DD" value-format="YYYY-MM-DD" /></el-form-item>
        <el-form-item label="开始时间"><el-time-picker v-model="createForm.startTime" format="HH:mm" value-format="HH:mm" /></el-form-item>
        <el-form-item label="结束时间"><el-time-picker v-model="createForm.endTime" format="HH:mm" value-format="HH:mm" /></el-form-item>
        <el-form-item label="事由"><el-input v-model="createForm.purpose" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAdminCreate" :loading="creating">提交</el-button>
      </template>
    </el-dialog>

    <!-- 批量导入对话框 -->
    <el-dialog v-model="batchDialogVisible" title="批量Excel导入" width="500px">
      <p style="margin-bottom:10px">Excel格式：实验室ID | 日期 | 开始时间 | 结束时间 | 事由 | 用户ID（首行为标题行）</p>
      <el-upload drag :auto-upload="false" :on-change="handleFileChange" accept=".xlsx" :limit="1">
        <el-icon><UploadFilled /></el-icon>
        <div>拖拽或点击上传Excel文件</div>
      </el-upload>
      <el-button type="primary" @click="handleBatchImport" :loading="importing" style="margin-top:10px;width:100%">开始导入</el-button>
      <div v-if="importResults.length" style="margin-top:10px;max-height:200px;overflow-y:auto">
        <p v-for="(r,i) in importResults" :key="i" :style="{color:r.includes('成功')?'green':'orange'}">{{ r }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getReservationList, approveReservation, forceApproveReservation, adminCancelReservation, adminCreateReservation, getOverview } from '@/api/reservation'
import { getLabList } from '@/api/lab'
import { ElMessage, ElMessageBox } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import request from '@/api/request'

const activeTab = ref('list')
const statusMap = { PENDING: { text: '待审批', type: 'warning' }, APPROVED: { text: '已通过', type: 'success' }, REJECTED: { text: '已拒绝', type: 'danger' }, CANCELED: { text: '已取消', type: 'info' } }
const getStatusType = s => statusMap[s]?.type || 'info'
const getStatusText = s => statusMap[s]?.text || s

const queryForm = ref({ labId: null, status: null })
const tableData = ref([]); const loading = ref(false)
const pagination = ref({ current: 1, size: 10 }); const total = ref(0)
const labList = ref([]); const labMap = ref({})

// Overview
const overviewDate = ref(''); const overviewData = ref([]); const overviewLoading = ref(false)

// Create dialog
const createDialogVisible = ref(false); const creating = ref(false)
const createForm = ref({ userId: null, labId: null, date: '', startTime: '', endTime: '', purpose: '' })

// Batch import
const batchDialogVisible = ref(false); const importFile = ref(null); const importing = ref(false)
const importResults = ref([])

function resetQuery() { queryForm.value = { labId: null, status: null }; loadData() }

async function loadData() {
  loading.value = true
  try {
    const res = await getReservationList({ current: pagination.value.current, size: pagination.value.size, labId: queryForm.value.labId, userId: null, status: queryForm.value.status })
    tableData.value = res.data.records.map(item => ({ ...item, labName: labMap.value[item.labId] || item.labId }))
    total.value = res.data.total
  } catch (e) { console.error(e) } finally { loading.value = false }
}

async function loadOverview() {
  if (!overviewDate.value) return
  overviewLoading.value = true
  try {
    const res = await getOverview(overviewDate.value)
    overviewData.value = (res.data || []).map(item => ({ ...item, labName: labMap.value[item.labId] || item.labId }))
  } catch (e) { console.error(e) } finally { overviewLoading.value = false }
}

function onTabChange(tab) { if (tab === 'overview') loadOverview() }

const handleApprove = async (row, status) => {
  loading.value = true
  try {
    await approveReservation(row.id, status, '')
    ElMessage.success(status === 'APPROVED' ? '审批通过' : '已拒绝')
    loadData()
  } catch (error) {
    if (error.response?.status === 409) {
      const conflicts = error.response.data?.data || []
      try {
        await ElMessageBox.confirm(`该时间段与 ${conflicts.length} 个预约冲突\n\n是否强制审批（自动拒绝冲突）？`, '冲突', { confirmButtonText: '强制审批', cancelButtonText: '取消', type: 'warning' })
        await forceApproveReservation(row.id, '')
        ElMessage.success('强制审批成功')
        loadData()
      } catch { /* canceled */ }
    } else { ElMessage.error('审批失败') }
  } finally { loading.value = false }
}

async function handleAdminCancel(row) {
  try {
    await ElMessageBox.confirm(`确定撤销预约 #${row.id}？`, '确认')
    await adminCancelReservation(row.id)
    ElMessage.success('已撤销')
    loadData()
  } catch { /* canceled */ }
}

function showCreateDialog() { createForm.value = { userId: null, labId: null, date: '', startTime: '', endTime: '', purpose: '' }; createDialogVisible.value = true }

async function handleAdminCreate() {
  creating.value = true
  try {
    await request({ url: '/reservation/admin-create', method: 'post', params: {
      targetUserId: createForm.value.userId,
      labId: createForm.value.labId,
      reservationDate: createForm.value.date,
      startTime: createForm.value.startTime,
      endTime: createForm.value.endTime,
      purpose: createForm.value.purpose
    }})
    ElMessage.success('预约创建成功')
    createDialogVisible.value = false
    loadData()
  } catch { ElMessage.error('创建失败') } finally { creating.value = false }
}

function showBatchDialog() { importResults.value = []; batchDialogVisible.value = true }

function handleFileChange(file) { importFile.value = file.raw }

async function handleBatchImport() {
  if (!importFile.value) { ElMessage.warning('请选择文件'); return }
  importing.value = true
  try {
    const fd = new FormData(); fd.append('file', importFile.value)
    const res = await request({ url: '/reservation/batch-import', method: 'post', data: fd, headers: { 'Content-Type': 'multipart/form-data' } })
    importResults.value = res.data || []
    ElMessage.success('导入完成')
    loadData()
  } catch { ElMessage.error('导入失败') } finally { importing.value = false }
}

onMounted(async () => {
  const res = await getLabList()
  labList.value = res.data
  res.data.forEach(lab => { labMap.value[lab.id] = lab.name })
  loadData()
})
</script>
