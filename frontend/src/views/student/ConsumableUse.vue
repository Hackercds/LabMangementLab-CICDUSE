<template>
  <div>
    <h2>耗材领用</h2>
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="name" label="耗材名称" width="150" />
      <el-table-column prop="specification" label="规格" width="120" />
      <el-table-column prop="unit" label="单位" width="60" />
      <el-table-column prop="currentStock" label="当前库存" width="100" />
      <el-table-column prop="warningThreshold" label="预警阈值" width="100" />
      <el-table-column prop="location" label="存放位置" width="150" />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag v-if="row.currentStock <= row.warningThreshold && row.warningThreshold > 0" type="danger">
            库存不足
          </el-tag>
          <el-tag v-else type="success">充足</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="120">
        <template #default="{ row }">
          <el-button type="primary" size="small" @click="openUseDialog(row)"
            :disabled="row.currentStock <= 0">
            领用
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 领用对话框 -->
    <el-dialog v-model="useDialogVisible" title="领用耗材">
      <el-form :model="useForm" label-width="100px">
        <el-form-item label="耗材名称">
          <el-input :model-value="currentConsumable?.name" disabled />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input :model-value="currentConsumable?.currentStock + ' ' + currentConsumable?.unit" disabled />
        </el-form-item>
        <el-form-item label="领用数量">
          <el-input-number v-model="useForm.quantity" :min="1" :max="currentConsumable?.currentStock" />
        </el-form-item>
        <el-form-item label="用途">
          <el-input v-model="useForm.purpose" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="useDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleUse" :loading="using">提交领用</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getConsumableList, consumableOut } from '@/api/consumable'
import { ElMessage } from 'element-plus'

const tableData = ref([])
const loading = ref(false)
const useDialogVisible = ref(false)
const currentConsumable = ref(null)
const useForm = ref({ quantity: 1, purpose: '' })
const using = ref(false)

function openUseDialog(consumable) {
  currentConsumable.value = consumable
  useForm.value = { quantity: 1, purpose: '' }
  useDialogVisible.value = true
}

async function loadData() {
  loading.value = true
  try {
    const res = await getConsumableList()
    tableData.value = res.data
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

async function handleUse() {
  if (!useForm.value.quantity || useForm.value.quantity <= 0) {
    ElMessage.warning('请输入正确的领用数量')
    return
  }
  if (!useForm.value.purpose) {
    ElMessage.warning('请输入用途')
    return
  }
  try {
    using.value = true
    const res = await consumableOut(currentConsumable.value.id, {
      quantity: useForm.value.quantity,
      purpose: useForm.value.purpose,
      receiver: ''
    })
    ElMessage.success('领用成功')
    if (res.data) {
      ElMessage.warning('当前耗材库存已低于预警阈值，请及时补充')
    }
    useDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error(e)
  } finally {
    using.value = false
  }
}

onMounted(async () => {
  await loadData()
})
</script>

<style scoped>
</style>
