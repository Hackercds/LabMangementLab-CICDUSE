import { createRouter, createWebHashHistory } from 'vue-router'
import { useUserStore } from '@/store'
import { ElMessage } from 'element-plus'
import Login from '@/views/login/Login.vue'
import Register from '@/views/register/Register.vue'

// 路由配置
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/register',
    name: 'Register',
    component: Register
  },
  // 学生端路由
  {
    path: '/student',
    name: 'StudentHome',
    component: () => import('@/views/student/Home.vue'),
    meta: { requiresAuth: true, role: 'STUDENT' },
    children: [
      {
        path: 'home',
        redirect: '/student/reservation'
      },
      {
        path: 'reservation',
        name: 'StudentReservation',
        component: () => import('@/views/student/Reservation.vue'),
        meta: { title: '实验室预约' }
      },
      {
        path: 'my-reservation',
        name: 'MyReservation',
        component: () => import('@/views/student/MyReservation.vue'),
        meta: { title: '我的预约' }
      },
      {
        path: 'device',
        name: 'StudentDevice',
        component: () => import('@/views/student/DeviceList.vue'),
        meta: { title: '设备查询' }
      },
      {
        path: 'consumable',
        name: 'StudentConsumable',
        component: () => import('@/views/student/ConsumableUse.vue'),
        meta: { title: '耗材领用' }
      },
      {
        path: 'personal',
        name: 'StudentPersonal',
        component: () => import('@/views/student/Personal.vue'),
        meta: { title: '个人中心' }
      }
    ]
  },
  // 教师端路由
  {
    path: '/teacher',
    name: 'TeacherHome',
    component: () => import('@/views/teacher/Home.vue'),
    meta: { requiresAuth: true, role: 'TEACHER' },
    children: [
      {
        path: 'reservation',
        name: 'TeacherReservation',
        component: () => import('@/views/student/Reservation.vue'),
        meta: { title: '实验室预约' }
      },
      {
        path: 'my-reservation',
        name: 'TeacherMyReservation',
        component: () => import('@/views/student/MyReservation.vue'),
        meta: { title: '我的预约' }
      },
      {
        path: 'approve',
        name: 'ApproveReservation',
        component: () => import('@/views/teacher/ApproveReservation.vue'),
        meta: { title: '预约审批' }
      },
      {
        path: 'device',
        name: 'TeacherDevice',
        component: () => import('@/views/student/DeviceList.vue'),
        meta: { title: '设备查询' }
      },
      {
        path: 'consumable',
        name: 'TeacherConsumable',
        component: () => import('@/views/student/ConsumableUse.vue'),
        meta: { title: '耗材领用' }
      },
      {
        path: 'personal',
        name: 'TeacherPersonal',
        component: () => import('@/views/student/Personal.vue'),
        meta: { title: '个人中心' }
      }
    ]
  },
  // 管理员端路由
  {
    path: '/admin',
    name: 'AdminHome',
    component: () => import('@/views/admin/Home.vue'),
    meta: { requiresAuth: true, role: 'ADMIN' },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/admin/Dashboard.vue'),
        meta: { title: '仪表盘' }
      },
      {
        path: 'user',
        name: 'UserManage',
        component: () => import('@/views/admin/UserManage.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: 'lab',
        name: 'LabManage',
        component: () => import('@/views/admin/LabManage.vue'),
        meta: { title: '实验室管理' }
      },
      {
        path: 'device',
        name: 'DeviceManage',
        component: () => import('@/views/admin/DeviceManage.vue'),
        meta: { title: '设备管理' }
      },
      {
        path: 'reservation',
        name: 'ReservationManage',
        component: () => import('@/views/admin/ReservationManage.vue'),
        meta: { title: '预约管理' }
      },
      {
        path: 'consumable',
        name: 'ConsumableManage',
        component: () => import('@/views/admin/ConsumableManage.vue'),
        meta: { title: '耗材管理' }
      },
      {
        path: 'statistics',
        name: 'Statistics',
        component: () => import('@/views/admin/Statistics.vue'),
        meta: { title: '数据统计' }
      },
      {
        path: 'announcement',
        name: 'AnnouncementManage',
        component: () => import('@/views/admin/AnnouncementManage.vue'),
        meta: { title: '公告管理' }
      },
      {
        path: 'log',
        name: 'OperationLog',
        component: () => import('@/views/admin/OperationLog.vue'),
        meta: { title: '操作日志' }
      }
    ]
  },
  // 默认路由
  {
    path: '/',
    redirect: to => {
      const userStore = useUserStore()
      const role = userStore.userRole
      if (role === 'ADMIN') {
        return '/admin/dashboard'
      } else if (role === 'TEACHER') {
        return '/teacher/reservation'
      } else if (role === 'STUDENT') {
        return '/student/reservation'
      } else {
        return '/login'
      }
    }
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()

  if (to.meta.requiresAuth) {
    if (!userStore.isLoggedIn) {
      next('/login')
      return
    }
    if (to.meta.role && to.meta.role !== userStore.userRole) {
      ElMessage.error('权限不足')
      next(false)
      return
    }
  }

  // 已登录用户访问登录页，跳转到首页
  if (to.path === '/login' && userStore.isLoggedIn) {
    const role = userStore.userRole
    if (role === 'ADMIN') {
      next('/admin/dashboard')
    } else if (role === 'TEACHER') {
      next('/teacher/reservation')
    } else {
      next('/student/reservation')
    }
    return
  }

  next()
})

export default router
