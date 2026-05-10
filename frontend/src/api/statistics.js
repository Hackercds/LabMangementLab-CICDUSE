import request from '@/api/request'

// 获取仪表盘统计数据
export function getDashboardStats() {
  return request({
    url: '/statistics/dashboard',
    method: 'get'
  })
}

// 获取实验室使用率统计
export function getLabUsage(startDate, endDate) {
  return request({
    url: '/statistics/lab-usage',
    method: 'get',
    params: { startDate, endDate }
  })
}

// 获取设备借用频次统计
export function getDeviceBorrowStats(startDate, endDate) {
  return request({
    url: '/statistics/device-borrow',
    method: 'get',
    params: { startDate, endDate }
  })
}

// 导出实验室使用率Excel（带auth token）
export async function exportLabUsage(startDate, endDate) {
  const res = await request({
    url: '/statistics/export/lab-usage',
    method: 'get',
    params: { startDate, endDate },
    responseType: 'blob'
  })
  const url = window.URL.createObjectURL(new Blob([res]))
  const a = document.createElement('a'); a.href = url
  a.download = `lab-usage-${startDate}-${endDate}.xlsx`
  a.click(); window.URL.revokeObjectURL(url)
}
