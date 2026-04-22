<template>
  <div>
    <h2>仪表盘</h2>
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card>
          <div style="font-size: 14px; color: #999;">今日预约数</div>
          <div style="font-size: 32px; font-weight: bold; color: #409eff; margin-top: 10px;">
            {{ stats.todayReservationCount }}
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div style="font-size: 14px; color: #999;">待审批预约</div>
          <div style="font-size: 32px; font-weight: bold; color: #e6a23c; margin-top: 10px;">
            {{ stats.pendingApprovalCount }}
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div style="font-size: 14px; color: #999;">借用中设备</div>
          <div style="font-size: 32px; font-weight: bold; color: #6f42c1; margin-top: 10px;">
            {{ stats.borrowedDeviceCount }}
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <div style="font-size: 14px; color: #999;">低库存耗材</div>
          <div style="font-size: 32px; font-weight: bold; color: #f56c6c; margin-top: 10px;">
            {{ stats.lowStockConsumableCount }}
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row style="margin-top: 20px;">
      <el-col :span="24">
        <el-card>
          <div id="chart" style="height: 350px;"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import * as echarts from 'echarts'
import { getDashboardStats } from '@/api/statistics'

const stats = ref({
  todayReservationCount: 0,
  pendingApprovalCount: 0,
  borrowedDeviceCount: 0,
  lowStockConsumableCount: 0
})

let chart = null

async function loadData() {
  try {
    const res = await getDashboardStats()
    stats.value = res.data
    if (chart) {
      const option = {
        title: {
          left: 'center',
          text: '实验室平均使用率: ' + stats.value.labUsageRate + '%'
        },
        series: [{
          type: 'gauge',
          progress: {
            itemStyle: {
              color: '#409eff'
            }
          },
          pointer: {
            length: 80
          },
          axis: {
            width: 10
          },
          detail: {
            formatter: '{value}%',
            valueAnimation: true
          },
          data: [{
            value: Math.round(stats.value.labUsageRate || 0),
            name: '使用率'
          }]
        }]
      }
      chart.setOption(option)
    }
  } catch (e) {
    console.error(e)
  }
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
