// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue/dist/bootstrap-vue.esm'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
Vue.use(BootstrapVue)

import axios from 'axios'
// Configure axios defaults
axios.defaults.headers.post['Content-Type'] = 'application/json'
axios.defaults.headers.common['Accept'] = 'application/json'

// Make axios available globally as Vue.http and this.$http
Vue.prototype.$http = axios
Vue.http = axios

import App from '@/components/App'
import router from './router'
import store from './store'

Vue.config.productionTip = false

/* Auth plugin */
import Auth from './auth'
Vue.use(Auth)

// Configure axios interceptors after Auth plugin is installed
axios.interceptors.request.use((config) => {
  // Ensure Content-Type is set for POST requests
  if (config.method === 'post' && !config.headers['Content-Type']) {
    config.headers['Content-Type'] = 'application/json'
  }

  const token = store.state.auth.accessToken
  const hasAuthHeader = config.headers && config.headers.Authorization
  const isLoginRequest = config.url && config.url.includes('/login')

  // Only add auth header if we have a token, no auth header exists, and it's not a login request
  if (token && !hasAuthHeader && !isLoginRequest) {
    if (!config.headers) {
      config.headers = {}
    }
    config.headers.Authorization = `Bearer ${token}`
    console.log('Adding auth token to request:', config.url, token.substring(0, 20) + '...')
  }

  return config
}, (error) => {
  return Promise.reject(error)
})

/* Zipkin tracing - temporarily disabled due to webpack issues */
// import Zipkin from './zipkin'
// Vue.use(Zipkin)

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  store,
  template: '<App/>',
  components: { App }
})
