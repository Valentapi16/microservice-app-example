import {
  Tracer,
  BatchRecorder,
  ExplicitContext,
  jsonEncoder
} from 'zipkin'
import {HttpLogger} from 'zipkin-transport-http'
import wrapAxios from 'zipkin-instrumentation-axios'
const ZIPKIN_URL = window.location.protocol + '//' + window.location.host + '/zipkin'
/**
* Tracing plugin that uses Zipkin. Initiates new traces with outgoing requests
* and injects appropriate headers.
*/
export default {

  /**
   * Install the Zipkin tracing.
   *
   * Creates an axios interceptor to handle automatically adding tracing headers.
   *
   * @param {Object} Vue The global Vue.
   * @param {Object} options Any options we want to have in our plugin.
   * @return {void}
   */
  install (Vue, options) {
    const serviceName = 'frontend'
    const tracer = new Tracer({
      ctxImpl: new ExplicitContext(),
      recorder: new BatchRecorder({
        logger: new HttpLogger({
          endpoint: ZIPKIN_URL,
          jsonEncoder: jsonEncoder.JSON_V2
        })
      }),
      localServiceName: serviceName
    })

    // Wrap axios with zipkin instrumentation
    const zipkinAxios = wrapAxios(Vue.http, { tracer, serviceName })
    Vue.prototype.$http = zipkinAxios
    Vue.http = zipkinAxios
  }
}
