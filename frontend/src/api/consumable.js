import request from '@/api/request'

// 获取全部耗材列表
export function getConsumableList() {
  return request({
    url: '/consumable/list',
    method: 'get'
  })
}

// 分页查询耗材
export function getConsumablePage(params) {
  return request({
    url: '/consumable/page',
    method: 'get',
    params
  })
}

// 获取低库存耗材列表
export function getLowStockList() {
  return request({
    url: '/consumable/warning',
    method: 'get'
  })
}

// 获取耗材出入库记录
export function getConsumableLogs(id, params) {
  return request({
    url: `/consumable/${id}/logs`,
    method: 'get',
    params
  })
}

// 获取耗材详情
export function getConsumableDetail(id) {
  return request({
    url: `/consumable/${id}`,
    method: 'get'
  })
}

// 新增耗材
export function createConsumable(data) {
  return request({
    url: '/consumable',
    method: 'post',
    data
  })
}

// 更新耗材
export function updateConsumable(id, data) {
  return request({
    url: `/consumable/${id}`,
    method: 'put',
    data
  })
}

// 删除耗材
export function deleteConsumable(id) {
  return request({
    url: `/consumable/${id}`,
    method: 'delete'
  })
}

// 入库
export function consumableIn(id, data) {
  return request({
    url: `/consumable/${id}/in`,
    method: 'post',
    data
  })
}

// 领用出库
export function consumableOut(id, data) {
  return request({
    url: `/consumable/${id}/out`,
    method: 'post',
    data
  })
}
