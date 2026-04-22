import request from '@/api/request'

// 分页查询操作日志
function pageList(current, size, operatorId, module, operationType) {
  return request({
    url: '/operation-log/page',
    method: 'get',
    params: { current, size, operatorId, module, operationType }
  })
}

export default { pageList }
