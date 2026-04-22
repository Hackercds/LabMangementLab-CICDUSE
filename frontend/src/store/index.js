import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getToken, getUserInfo, setToken, setUserInfo, clearAuth } from '@/utils/auth'

export const useUserStore = defineStore('user', () => {
  const token = ref(getToken() || '')
  const userInfo = ref(getUserInfo() || null)

  const isLoggedIn = computed(() => !!token.value)
  const userRole = computed(() => userInfo.value?.role || null)

  function setAuth(authData) {
    setToken(authData.token)
    setUserInfo({
      userId: authData.userId,
      username: authData.username,
      realName: authData.realName,
      role: authData.role
    })
    token.value = authData.token
    userInfo.value = {
      userId: authData.userId,
      username: authData.username,
      realName: authData.realName,
      role: authData.role
    }
  }

  function logout() {
    clearAuth()
    token.value = ''
    userInfo.value = null
  }

  return {
    token,
    userInfo,
    isLoggedIn,
    userRole,
    setAuth,
    logout
  }
})
