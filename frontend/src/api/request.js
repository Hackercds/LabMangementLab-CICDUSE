import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getToken, clearAuth } from '@/utils/auth'
import { useUserStore } from '@/store'

const service = axios.create({
  baseURL: '/api',
  timeout: 10000
})

// 请求拦截器：添加token
service.interceptors.request.use(
  config => {
    const token = getToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    console.error('请求错误', error)
    return Promise.reject(error)
  }
)

// 响应拦截器：处理响应
service.interceptors.response.use(
  response => {
    const res = response.data
    if (res.code !== 200) {
      ElMessage({
        message: res.message || '请求失败',
        type: 'error',
        duration: 5000
      })
      // 401 仅在业务明确返回"未认证"时才处理，其他业务错误不登出
      if (res.code === 401 && (
        res.message.includes('未认证') ||
        res.message.includes('登录已过期') ||
        res.message.includes('认证失败')
      )) {
        ElMessageBox.confirm('登录已过期，请重新登录', '提示', {
          confirmButtonText: '去登录',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          clearAuth()
          const userStore = useUserStore()
          userStore.logout()
          window.location.href = '/#/login'
        })
      }
      return Promise.reject(new Error(res.message || '请求失败'))
    }
    return res
  },
  error => {
    console.error('响应错误', error)
    let message = error.message || '网络错误'
    if (error.response && error.response.status === 401) {
      clearAuth()
      window.location.href = '/#/login'
      return Promise.reject(error)
    }
    // 409冲突错误，将错误信息传递给调用方处理
    if (error.response && error.response.status === 409) {
      return Promise.reject(error)
    }
    ElMessage({
      message: message,
      type: 'error',
      duration: 5000
    })
    return Promise.reject(error)
  }
)

export default service
