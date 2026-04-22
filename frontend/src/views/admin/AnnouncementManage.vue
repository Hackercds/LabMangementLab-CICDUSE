<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <h2>公告管理</h2>
      <el-button type="primary" @click="openDialog('create')">发布公告</el-button>
    </div>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="全部状态" clearable>
          <el-option label="草稿" value="DRAFT" />
          <el-option label="已发布" value="PUBLISHED" />
          <el-option label="已关闭" value="CLOSED" />
        </el-select>
      </el-form-item>
      <el-form-item label="关键词">
        <el-input v-model="queryForm.keyword" placeholder="标题关键词" clearable style="width: 200px;" />
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="title" label="标题" min-width="200" />
      <el-table-column prop="isTop" label="置顶" width="80">
        <template #default="{ row }">
          <el-tag v-if="row.isTop" type="success">是</el-tag>
          <el-tag v-else type="info">否</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="publishTime" label="发布时间" width="170" />
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

    <el-dialog v-model="dialogVisible" :title="dialogType === 'create' ? '发布公告' : '编辑公告'" width="600px">
      <el-form :model="formData" label-width="80px">
        <el-form-item label="标题">
          <el-input v-model="formData.title" />
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="formData.content" type="textarea" :rows="8" />
        </el-form-item>
        <el-form-item label="置顶">
          <el-switch v-model="formData.isTop" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="formData.status">
            <el-radio label="DRAFT">草稿</el-radio>
            <el-radio label="PUBLISHED">发布</el-radio>
          </el-radio-group>
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
import { getAdminAnnouncement, createAnnouncement, updateAnnouncement, deleteAnnouncement } from '@/api/announcement'
import { ElMessage, ElMessageBox } from 'element-plus'

const statusMap = {
  DRAFT: { text: '草稿', type: 'info' },
  PUBLISHED: { text: '已发布', type: 'success' },
  CLOSED: { text: '已关闭', type: 'danger' }
}

function getStatusType(status) {
  return statusMap[status]?.type || 'info'
}
function getStatusText(status) {
  return statusMap[status]?.text || status
}

const queryForm = ref({ status: null, keyword: '' })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const dialogVisible = ref(false)
const dialogType = ref('create')
const formData = ref({})
const submitting = ref(false)

function resetQuery() {
  queryForm.value = { status: null, keyword: '' }
  loadData()
}

function openDialog(type, row) {
  dialogType.value = type
  if (type === 'create') {
    formData.value = {
      title: '',
      content: '',
      isTop: false,
      status: 'PUBLISHED'
    }
  } else {
    formData.value = {
      ...row,
      isTop: !!row.isTop
    }
  }
  dialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getAdminAnnouncement({
      current: pagination.value.current,
      size: pagination.value.size,
      status: queryForm.value.status,
      keyword: queryForm.value.keyword
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
      await createAnnouncement(formData.value)
      ElMessage.success('发布成功')
    } else {
      await updateAnnouncement(formData.value.id, formData.value)
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
    await ElMessageBox.confirm(`确定要删除公告 "${row.title}"吗？`, '提示', { type: 'warning' })
    await deleteAnnouncement(row.id)
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
