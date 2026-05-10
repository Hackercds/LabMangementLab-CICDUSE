<template>
  <div>
    <h2>数据统计</h2>
    <el-card>
      <el-form :inline="true">
        <el-form-item label="时间范围">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至"
            start-placeholder="开始" end-placeholder="结束"
            format="YYYY-MM-DD" value-format="YYYY-MM-DD" />
        </el-form-item>
        <el-form-item label="搜索实验室">
          <el-input v-model="searchLab" placeholder="实验室名称" clearable style="width:180px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button type="success" @click="handleExport">导出Excel</el-button>
        </el-form-item>
      </el-form>

      <div id="chart" style="height:350px;margin:10px 0" />
    </el-card>

    <el-card style="margin-top:15px">
      <template v-for="lab in filteredData" :key="lab.labName">
        <h3 style="margin:15px 0 10px">
          {{ lab.labName }}
          <el-tag size="small" type="info" style="margin-left:10px">{{ lab.totalReservations }}次 / {{ lab.totalHours }}h</el-tag>
          <el-tag size="small" :type="lab.usageRate > 50 ? 'danger' : 'success'">{{ lab.usageRate.toFixed(1) }}%</el-tag>
        </h3>
        <el-table :data="lab.reservations" border size="small" empty-text="该时段无预约">
          <el-table-column prop="date" label="日期" width="110" />
          <el-table-column label="时间段" width="120">
            <template #default="{row}">{{ row.startTime }}-{{ row.endTime }}</template>
          </el-table-column>
          <el-table-column prop="purpose" label="事由" min-width="150" />
          <el-table-column label="预约人" width="150">
            <template #default="{row}">{{ row.realName }}({{ row.username }})</template>
          </el-table-column>
        </el-table>
      </template>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getLabUsage, exportLabUsage } from '@/api/statistics'

const dateRange = ref([
  new Date(new Date().getFullYear(), new Date().getMonth()-1, 1).toISOString().split('T')[0],
  new Date().toISOString().split('T')[0]
])
const searchLab = ref('')
const tableData = ref([])
let chart = null

const filteredData = computed(() => {
  if (!searchLab.value) return tableData.value
  return tableData.value.filter(l => l.labName.includes(searchLab.value))
})

function renderChart(data) {
  if (!chart) chart = echarts.init(document.getElementById('chart'))
  const names = data.map(d => d.labName)
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['预约次数','使用小时','使用率%'] },
    xAxis: { type: 'category', data: names, axisLabel: { rotate: 30 } },
    yAxis: [{ type: 'value', name: '次/时' }, { type: 'value', name: '%', max: 100 }],
    series: [
      { name: '预约次数', type: 'bar', data: data.map(d => d.totalReservations), itemStyle: { color: '#409eff' } },
      { name: '使用小时', type: 'bar', data: data.map(d => d.totalHours), itemStyle: { color: '#67c23a' } },
      { name: '使用率%', type: 'line', yAxisIndex: 1, data: data.map(d => +d.usageRate.toFixed(1)), itemStyle: { color: '#e6a23c' } }
    ]
  })
}

async function loadData() {
  try {
    const res = await getLabUsage(dateRange.value[0], dateRange.value[1])
    tableData.value = res.data || []
    nextTick(() => renderChart(tableData.value))
  } catch(e) { console.error(e) }
}

function handleExport() {
  window.open(`/api/statistics/export/lab-usage?startDate=${dateRange.value[0]}&endDate=${dateRange.value[1]}`)
}

onMounted(loadData)
</script>
