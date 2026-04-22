import request from '@/api/request'

// 获取公开公告列表
export function getPublicAnnouncement(params) {
  return request({
    url: '/announcement/list',
    method: 'get',
    params
  })
}

// 获取公告详情
export function getAnnouncementDetail(id) {
  return request({
    url: `/announcement/${id}`,
    method: 'get'
  })
}

// 管理端获取公告列表
export function getAdminAnnouncement(params) {
  return request({
    url: '/announcement/admin/page',
    method: 'get',
    params
  })
}

// 新增公告
export function createAnnouncement(data) {
  return request({
    url: '/announcement',
    method: 'post',
    data
  })
}

// 更新公告
export function updateAnnouncement(id, data) {
  return request({
    url: `/announcement/${id}`,
    method: 'put',
    data
  })
}

// 删除公告
export function deleteAnnouncement(id) {
  return request({
    url: `/announcement/${id}`,
    method: 'delete'
  })
}
