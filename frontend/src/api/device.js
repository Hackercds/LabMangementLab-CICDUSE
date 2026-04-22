import request from '@/api/request'

// 获取设备列表
export function getDeviceList(params) {
  return request({
    url: '/device/list',
    method: 'get',
    params
  })
}

// 分页查询设备
export function getDevicePage(params) {
  return request({
    url: '/device/page',
    method: 'get',
    params
  })
}

// 获取设备详情
export function getDeviceDetail(id) {
  return request({
    url: `/device/${id}`,
    method: 'get'
  })
}

// 新增设备
export function createDevice(data) {
  return request({
    url: '/device',
    method: 'post',
    data
  })
}

// 更新设备
export function updateDevice(id, data) {
  return request({
    url: `/device/${id}`,
    method: 'put',
    data
  })
}

// 删除设备
export function deleteDevice(id) {
  return request({
    url: `/device/${id}`,
    method: 'delete'
  })
}

// 借用设备
export function borrowDevice(id, data) {
  return request({
    url: `/device/${id}/borrow`,
    method: 'post',
    data
  })
}

// 归还设备
export function returnDevice(id) {
  return request({
    url: `/device/${id}/return`,
    method: 'post'
  })
}
