import request from '@/api/request'

// 获取全部实验室列表
export function getLabList() {
  return request({
    url: '/lab/list',
    method: 'get'
  })
}

// 分页查询实验室
export function getLabPage(params) {
  return request({
    url: '/lab/page',
    method: 'get',
    params
  })
}

// 获取实验室详情
export function getLabDetail(id) {
  return request({
    url: `/lab/${id}`,
    method: 'get'
  })
}

// 新增实验室
export function createLab(data) {
  return request({
    url: '/lab',
    method: 'post',
    data
  })
}

// 更新实验室
export function updateLab(id, data) {
  return request({
    url: `/lab/${id}`,
    method: 'put',
    data
  })
}

// 删除实验室
export function deleteLab(id) {
  return request({
    url: `/lab/${id}`,
    method: 'delete'
  })
}
