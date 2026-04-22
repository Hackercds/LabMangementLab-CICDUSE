import request from '@/api/request'

// 获取已占用时间段
export function getBusyTimes(labId, date) {
  return request({
    url: '/reservation/busy',
    method: 'get',
    params: { labId, date }
  })
}

// 获取我的预约列表
export function getMyReservation(params) {
  return request({
    url: '/reservation/my',
    method: 'get',
    params
  })
}

// 获取预约列表（管理端）
export function getReservationList(params) {
  return request({
    url: '/reservation/list',
    method: 'get',
    params
  })
}

// 获取预约详情
export function getReservationDetail(id) {
  return request({
    url: `/reservation/${id}`,
    method: 'get'
  })
}

// 提交预约申请
export function createReservation(data) {
  return request({
    url: '/reservation',
    method: 'post',
    data
  })
}

// 取消预约
export function cancelReservation(id) {
  return request({
    url: `/reservation/${id}/cancel`,
    method: 'put'
  })
}

// 审批预约
export function approveReservation(id, status, comment) {
  return request({
    url: `/reservation/${id}/approve`,
    method: 'put',
    params: { status, comment }
  })
}
