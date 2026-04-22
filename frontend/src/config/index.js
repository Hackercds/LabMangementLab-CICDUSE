/**
 * 应用配置
 * 从环境变量中读取配置
 */

export const config = {
  // 应用信息
  app: {
    title: import.meta.env.VITE_APP_TITLE || '实验室管理系统',
    env: import.meta.env.VITE_APP_ENV || 'development',
    version: '1.0.0'
  },

  // API配置
  api: {
    baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
    timeout: parseInt(import.meta.env.VITE_API_TIMEOUT) || 10000,
    withCredentials: true
  },

  // 上传配置
  upload: {
    maxSize: parseInt(import.meta.env.VITE_UPLOAD_MAX_SIZE) || 10 * 1024 * 1024,
    allowedTypes: (import.meta.env.VITE_UPLOAD_ALLOWED_TYPES || 'jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx').split(',')
  },

  // 功能开关
  features: {
    enableMock: import.meta.env.VITE_ENABLE_MOCK === 'true',
    enableDebug: import.meta.env.VITE_ENABLE_DEBUG === 'true',
    enableConsoleLog: import.meta.env.VITE_ENABLE_CONSOLE_LOG === 'true'
  },

  // Token配置
  token: {
    key: import.meta.env.VITE_TOKEN_KEY || 'lab_token',
    prefix: import.meta.env.VITE_TOKEN_PREFIX || 'Bearer '
  },

  // 语言配置
  i18n: {
    defaultLanguage: import.meta.env.VITE_DEFAULT_LANGUAGE || 'zh-CN',
    fallbackLanguage: 'zh-CN'
  },

  // 分页配置
  pagination: {
    pageSize: 10,
    pageSizes: [10, 20, 50, 100],
    layout: 'total, sizes, prev, pager, next, jumper'
  },

  // 日期格式配置
  dateFormat: {
    date: 'YYYY-MM-DD',
    datetime: 'YYYY-MM-DD HH:mm:ss',
    time: 'HH:mm:ss'
  },

  // 业务配置
  business: {
    reservation: {
      maxDaysInAdvance: 30,
      minHoursInAdvance: 2,
      maxHoursPerDay: 8,
      cancelHoursInAdvance: 24
    },
    device: {
      maxBorrowDays: 30,
      overdueFinePerDay: 10.0
    },
    consumable: {
      warningThreshold: 10,
      autoWarningEnabled: true
    }
  }
}

/**
 * 获取配置值
 */
export function getConfig(key, defaultValue = null) {
  const keys = key.split('.')
  let value = config
  
  for (const k of keys) {
    if (value && typeof value === 'object' && k in value) {
      value = value[k]
    } else {
      return defaultValue
    }
  }
  
  return value
}

/**
 * 判断是否为开发环境
 */
export function isDevelopment() {
  return config.app.env === 'development'
}

/**
 * 判断是否为生产环境
 */
export function isProduction() {
  return config.app.env === 'production'
}

/**
 * 判断是否为测试环境
 */
export function isTest() {
  return config.app.env === 'test'
}

/**
 * 打印配置信息（仅开发环境）
 */
export function printConfig() {
  if (isDevelopment() && config.features.enableConsoleLog) {
    console.group('🚀 应用配置信息')
    console.log('环境:', config.app.env)
    console.log('API地址:', config.api.baseURL)
    console.log('完整配置:', config)
    console.groupEnd()
  }
}

export default config
