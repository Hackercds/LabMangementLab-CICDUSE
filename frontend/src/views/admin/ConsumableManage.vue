<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <h2>耗材管理</h2>
      <el-button type="primary" @click="openDialog('create')">新增耗材</el-button>
    </div>
    <el-form :inline="true" :model="queryForm">
      <el-form-item label="关键词">
        <el-input v-model="queryForm.keyword" placeholder="名称/规格" clearable style="width: 200px;" />
      </el-form-item>
      <el-form-item>
        <el-button @click="loadData" type="primary">查询</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>
    <el-alert
      v-if="lowStockCount > 0"
      :title="`有 ${lowStockCount} 个耗材库存低于预警阈值，请及时补充`"
      type="warning"
      show-icon
      style="margin-bottom: 16px;"
    />
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="name" label="名称" width="150" />
      <el-table-column prop="specification" label="规格" width="120" />
      <el-table-column prop="unit" label="单位" width="60" />
      <el-table-column prop="currentStock" label="当前库存" width="100" />
      <el-table-column prop="warningThreshold" label="预警阈值" width="100" />
      <el-table-column prop="location" label="存放位置" width="150" />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag v-if="row.currentStock <= row.warningThreshold && row.warningThreshold > 0" type="danger">
            低库存
          </el-tag>
          <el-tag v-else type="success">正常</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220">
        <template #default="{ row }">
          <el-button size="small" @click="openInDialog(row)">入库</el-button>
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

    <!-- 新增编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogType === 'create' ? '新增耗材' : '编辑耗材'" width="500px">
      <el-form :model="formData" label-width="100px">
        <el-form-item label="耗材名称">
          <el-input v-model="formData.name" />
        </el-form-item>
        <el-form-item label="规格">
          <el-input v-model="formData.specification" />
        </el-form-item>
        <el-form-item label="单位">
          <el-input v-model="formData.unit" placeholder="例如：个/包/箱" />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input-number v-model="formData.currentStock" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="预警阈值">
          <el-input-number v-model="formData.warningThreshold" :min="0" :precision="2" />
          <div style="font-size: 12px; color: #999;">库存低于此值会发出预警，0表示不预警</div>
        </el-form-item>
        <el-form-item label="存放位置">
          <el-input v-model="formData.location" />
        </el-form-item>
        <el-form-item label="负责人">
          <el-input v-model="formData.director" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">提交</el-button>
      </template>
    </el-dialog>

    <!-- 入库对话框 -->
    <el-dialog v-model="inDialogVisible" title="耗材入库" width="450px">
      <el-form :model="inForm" label-width="100px">
        <el-form-item label="耗材名称">
          <el-input :model-value="currentConsumable?.name" disabled />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input :model-value="currentConsumable?.currentStock + ' ' + currentConsumable?.unit" disabled />
        </el-form-item>
        <el-form-item label="入库数量">
          <el-input-number v-model="inForm.quantity" :min="1" :precision="2" />
        </el-form-item>
        <el-form-item label="备注用途">
          <el-input v-model="inForm.purpose" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="inDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleIn" :loading="inSubmitting">确认入库</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { getConsumablePage, createConsumable, updateConsumable, deleteConsumable, consumableIn } from '@/api/consumable'
import { ElMessage, ElMessageBox } from 'element-plus'

const queryForm = ref({ keyword: '' })
const tableData = ref([])
const loading = ref(false)
const pagination = ref({ current: 1, size: 10 })
const total = ref(0)
const dialogVisible = ref(false)
const inDialogVisible = ref(false)
const dialogType = ref('create')
const formData = ref({})
const inForm = ref({ quantity: 1, purpose: '' })
const currentConsumable = ref(null)
const submitting = ref(false)
const inSubmitting = ref(false)

const lowStockCount = computed(() => {
  return tableData.value.filter(
    item => item.currentStock <= item.warningThreshold && item.warningThreshold > 0
  ).length
})

function resetQuery() {
  queryForm.value = { keyword: '' }
  loadData()
}

function openDialog(type, row) {
  dialogType.value = type
  if (type === 'create') {
    formData.value = {
      name: '',
      specification: '',
      unit: '',
      currentStock: 0,
      warningThreshold: 0,
      location: '',
      director: ''
    }
  } else {
    formData.value = { ...row }
  }
  dialogVisible.value = true
}

function openInDialog(row) {
  currentConsumable.value = row
  inForm.value = { quantity: 1, purpose: '' }
  inDialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getConsumablePage({
      current: pagination.value.current,
      size: pagination.value.size,
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
      await createConsumable(formData.value)
      ElMessage.success('新增成功')
    } else {
      await updateConsumable(formData.value.id, formData.value)
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

async function handleIn() {
  if (!inForm.value.quantity || inForm.value.quantity <= 0) {
    ElMessage.warning('请输入正确的入库数量')
    return
  }
  try {
    inSubmitting.value = true
    await consumableIn(currentConsumable.value.id, {
      quantity: inForm.value.quantity,
      purpose: inForm.value.purpose
    })
    ElMessage.success('入库成功')
    inDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error(e)
  } finally {
    inSubmitting.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定要删除耗材 "${row.name}"吗？`, '提示', { type: 'warning' })
    await deleteConsumable(row.id)
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
