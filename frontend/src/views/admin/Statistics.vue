<template>
  <div>
    <h2>数据统计</h2>
    <el-card>
      <el-form :inline="true" :model="dateRange">
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange.value"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button type="success" @click="handleExport">导出Excel</el-button>
        </el-form-item>
      </el-form>
      <div id="chart" style="height: 400px; margin-top: 20px;"></div>
      <el-table :data="tableData" border style="margin-top: 20px;">
        <el-table-column prop="labName" label="实验室名称" width="200" />
        <el-table-column prop="totalReservations" label="预约次数" width="120" />
        <el-table-column prop="totalHours" label="使用小时" width="100" />
        <el-table-column prop="usageRate" label="使用率%" width="100">
          <template #default="{ row }">
            {{ row.usageRate.toFixed(2) }}
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import * as echarts from 'echarts'
import { getLabUsage, exportLabUsage } from '@/api/statistics'

const dateRange = ref({
  value: [
    new Date(new Date().getFullYear(), new Date().getMonth() - 1, 1).toISOString().split('T')[0],
    new Date().toISOString().split('T')[0]
  ]
})
const tableData = ref([])
let chart = null

async function loadData() {
  if (!dateRange.value.value || dateRange.value.value.length !== 2) {
    return
  }
  try {
    const res = await getLabUsage(dateRange.value.value[0], dateRange.value.value[1])
    tableData.value = res.data
    // 渲染图表
    const xData = res.data.map(item => item.labName)
    const yData = res.data.map(item => item.usageRate)
    const option = {
      title: {
        text: '实验室使用率统计',
        left: 'center'
      },
      xAxis: {
        type: 'category',
        data: xData,
        axisLabel: {
          rotate: 30
        }
      },
      yAxis: {
        type: 'value',
        max: 100,
        name: '使用率%'
      },
      series: [{
        data: yData,
        type: 'bar',
        label: {
          show: true,
          position: 'top',
          formatter: '{c}%'
        },
        itemStyle: {
          color: '#409eff'
        }
      }]
    }
    chart.setOption(option)
  } catch (e) {
    console.error(e)
  }
}

function handleExport() {
  if (!dateRange.value.value || dateRange.value.value.length !== 2) {
    ElMessage.warning('请先选择时间范围')
    return
  }
  exportLabUsage(dateRange.value.value[0], dateRange.value.value[1])
}

onMounted(() => {
  chart = echarts.init(document.getElementById('chart'))
  window.addEventListener('resize', () => {
    chart.resize()
  })
  loadData()
})
</script>

<style scoped>
</style>
