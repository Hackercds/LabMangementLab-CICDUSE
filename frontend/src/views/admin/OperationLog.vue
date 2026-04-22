<template>
  <div>
    <h2>操作日志</h2>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="操作模块">
        <el-select v-model="queryForm.module" placeholder="全部模块" clearable>
          <el-option label="认证登录" value="AUTH" />
          <el-option label="用户管理" value="USER" />
          <el-option label="实验室" value="LAB" />
          <el-option label="预约" value="RESERVATION" />
          <el-option label="设备" value="DEVICE" />
          <el-option label="耗材" value="CONSUMABLE" />
          <el-option label="公告" value="ANNOUNCEMENT" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="operatorId" label="操作人ID" width="80" />
      <el-table-column prop="module" label="模块" width="100" />
      <el-table-column prop="operationType" label="类型" width="100" />
      <el-table-column prop="description" label="描述" min-width="250" />
      <el-table-column prop="ipAddress" label="IP" width="120" />
      <el-table-column prop="operationTime" label="操作时间" width="170" />
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
import operationLogService from '@/api/operation-log'
import { ElMessage } from 'element-plus'

const queryForm = ref({ module: null })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)

function resetQuery() {
  queryForm.value = { module: null }
  loadData()
}

async function loadData() {
  loading.value = true
  try {
    const res = await operationLogService.pageList(
      pagination.value.current,
      pagination.value.size,
      null,
      queryForm.value.module,
      null
    )
    tableData.value = res.data.records
    total.value = res.data.total
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
</style>
