import Vue from 'vue'
import Router from 'vue-router'
import Auth from '@/auth'
import Login from '@/components/Login.vue'
import Todos from '@/components/Todos.vue'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/login',
      name: 'login',
      component: Login
    },
    {
      path: '/',
      alias: '/todos',
      name: 'todos',
      component: Todos,
      beforeEnter: requireLoggedIn
    }
  ]
})

function requireLoggedIn (to, from, next) {
  if (!Auth.isLoggedIn()) {
    next({
      path: '/login',
      query: { redirect: to.fullPath }
    })
  } else {
    next()
  }
}
