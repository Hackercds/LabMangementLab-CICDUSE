import request from './request'

export function getAutoApprove() {
  return request({
    url: '/system-config/auto-approve',
    method: 'get'
  })
}

export function updateConfig(key, value) {
  return request({
    url: '/system-config/update',
    method: 'put',
    params: { key, value }
  })
}
