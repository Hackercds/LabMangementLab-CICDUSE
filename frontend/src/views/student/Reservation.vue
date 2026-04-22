<template>
  <div>
    <h2>预约实验室</h2>
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="选择实验室">
        <el-select v-model="queryForm.labId" placeholder="请选择实验室" clearable style="width: 250px;">
          <el-option
            v-for="lab in labList"
            :key="lab.id"
            :label="lab.name"
            :value="lab.id"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="选择日期">
        <el-date-picker
          v-model="queryForm.date"
          type="date"
          placeholder="选择日期"
          format="YYYY-MM-DD"
          value-format="YYYY-MM-DD"
          :disabled="!queryForm.labId"
          :disabled-date="disabledDate"
          @change="loadBusyTimes"
        />
      </el-form-item>
    </el-form>

    <el-divider v-if="queryForm.labId && queryForm.date">时间段选择（蓝色为已选中，灰色为已占用）</el-divider>

    <div class="calendar-grid" v-if="queryForm.labId && queryForm.date">
      <div class="calendar-time-slot calendar-header">时间段</div>
      <div
        v-for="slot in timeSlots"
        :key="slot.start"
        class="calendar-time-slot"
        :class="{ busy: isBusy(slot), selected: isSelected(slot), free: !isBusy(slot) && !isSelected(slot) }"
        :disabled="isBusy(slot)"
        @click="toggleSelect(slot)"
      >
        {{ formatTime(slot.start) }}-{{ formatTime(slot.end) }}
      </div>
    </div>

    <div v-if="selectedSlots.length">
      <el-divider>预约信息</el-divider>
      <el-form :model="reservationForm" label-width="100px">
        <el-form-item label="预约事由">
          <el-input v-model="reservationForm.purpose" placeholder="请输入预约事由" />
        </el-form-item>
        <el-form-item label="参与人数">
          <el-input-number v-model="reservationForm.participantCount" :min="1" :max="200" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">提交预约申请</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getLabList } from '@/api/lab'
import { getBusyTimes, createReservation } from '@/api/reservation'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'

const router = useRouter()
const labList = ref([])
const queryForm = ref({
  labId: null,
  date: null
})
const busyTimes = ref([])
const selectedSlots = ref([])
const reservationForm = ref({
  purpose: '',
  participantCount: 1
})
const submitting = ref(false)

// 生成时间段，每节课1小时
const timeSlots = ref([])
for (let i = 8; i < 18; i++) {
  timeSlots.value.push({ start: i * 60, end: (i + 1) * 60 })
}

function formatTime(minutes) {
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`
}

function isBusy(slot) {
  for (const busy of busyTimes.value) {
    // 判断重叠: 新开始 < 已有结束 && 新结束 > 已有开始
    if (slot.start < toMinutes(busy.endTime) && slot.end > toMinutes(busy.startTime)) {
      return true
    }
  }
  return false
}

function toMinutes(time) {
  const [h, m] = time.split(':').map(Number)
  return h * 60 + m
}

function isSelected(slot) {
  return selectedSlots.value.some(s => s.start === slot.start)
}

function toggleSelect(slot) {
  if (isBusy(slot)) return
  const index = selectedSlots.value.findIndex(s => s.start === slot.start)
  if (index > -1) {
    selectedSlots.value.splice(index, 1)
  } else {
    selectedSlots.value.push({ ...slot })
  }
}

function disabledDate(time) {
  // 禁用过去的日期，只能选择今天或未来的日期
  return time.getTime() < new Date().setHours(0, 0, 0, 0)
}

function resetForm() {
  selectedSlots.value = []
  reservationForm.value.purpose = ''
  reservationForm.value.participantCount = 1
}

async function loadBusyTimes() {
  if (!queryForm.value.labId || !queryForm.value.date) return
  try {
    const res = await getBusyTimes(queryForm.value.labId, queryForm.value.date)
    busyTimes.value = res.data
  } catch (e) {
    console.error(e)
  }
}

async function handleSubmit() {
  if (!queryForm.value.labId || !queryForm.value.date) {
    ElMessage.warning('请选择实验室和日期')
    return
  }
  if (selectedSlots.value.length === 0) {
    ElMessage.warning('请选择至少一个时间段')
    return
  }
  if (!reservationForm.value.purpose) {
    ElMessage.warning('请输入预约事由')
    return
  }

  // 合并连续时间段
  const sorted = [...selectedSlots.value].sort((a, b) => a.start - b.start)
  const start = sorted[0].start
  const end = sorted[sorted.length - 1].end

  const startHour = Math.floor(start / 60)
  const endHour = Math.floor(end / 60)
  const startTime = `${startHour.toString().padStart(2, '0')}:00`
  const endTime = `${endHour.toString().padStart(2, '0')}:00`

  try {
    submitting.value = true
    await createReservation({
      labId: queryForm.value.labId,
      reservationDate: queryForm.value.date,
      startTime,
      endTime,
      purpose: reservationForm.value.purpose,
      participantCount: reservationForm.value.participantCount
    })
    ElMessage.success('预约申请提交成功，请等待审批')
    resetForm()
    router.push('/student/my-reservation')
  } catch (e) {
    console.error(e)
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  try {
    const res = await getLabList()
    labList.value = res.data
  } catch (e) {
    console.error(e)
  }
})
</script>

<style scoped>
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 10px;
  margin: 20px 0;
}
.calendar-time-slot {
  padding: 12px 16px;
  text-align: center;
  border-radius: 4px;
  cursor: pointer;
  user-select: none;
  transition: all 0.2s;
}
.calendar-header {
  background: #f5f7fa;
  font-weight: bold;
  cursor: default;
}
.free {
  background: #e8f4ff;
  border: 1px solid #409eff;
  color: #409eff;
}
.free:hover {
  background: #409eff;
  color: white;
}
.selected {
  background: #409eff;
  border: 1px solid #409eff;
  color: white;
}
.busy {
  background: #f5f5f5;
  border: 1px solid #dcdfe6;
  color: #c0c4cc;
  cursor: not-allowed;
}
</style>
