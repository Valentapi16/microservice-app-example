'use strict';
const express = require('express')
const bodyParser = require("body-parser")
const { expressjwt: jwt } = require('express-jwt')

const ZIPKIN_URL = process.env.ZIPKIN_URL || 'http://127.0.0.1:9411/api/v2/spans';
const {Tracer, 
  BatchRecorder,
  jsonEncoder: {JSON_V2}} = require('zipkin');
  const CLSContext = require('zipkin-context-cls');  
const {HttpLogger} = require('zipkin-transport-http');
const zipkinMiddleware = require('zipkin-instrumentation-express').expressMiddleware;

const logChannel = process.env.REDIS_CHANNEL || 'log_channel';
const redisClient = require("redis").createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`,
  password: process.env.REDIS_PASSWORD || null,
  socket: {
    reconnectStrategy: function (retries) {
      if (retries > 10) {
        console.log('Max Redis reconnection attempts reached');
        return false;
      }
      console.log(`Reconnecting to Redis, attempt #${retries}`);
      return Math.min(retries * 100, 2000);
    }
  }
});

// Connect to Redis
redisClient.connect().then(() => {
  console.log('Connected to Redis successfully');
}).catch((err) => {
  console.error('Failed to connect to Redis:', err);
});

redisClient.on('error', (err) => {
  console.error('Redis connection error:', err);
});

redisClient.on('ready', () => {
  console.log('Redis client ready');
});
const port = process.env.TODO_API_PORT || 8080
const jwtSecret = process.env.JWT_SECRET || "foo"

const app = express()

// tracing
const ctxImpl = new CLSContext('zipkin');
const recorder = new  BatchRecorder({
  logger: new HttpLogger({
    endpoint: ZIPKIN_URL,
    jsonEncoder: JSON_V2
  })
});
const localServiceName = 'todos-api';
const tracer = new Tracer({ctxImpl, recorder, localServiceName});


app.use(jwt({ 
  secret: jwtSecret, 
  algorithms: ['HS256'],
  requestProperty: 'user'
}).unless({
  path: ['/health', '/version', '/health/circuit-breaker']
}))

// Debugging middleware to check JWT payload
app.use((req, res, next) => {
  if (req.user) {
    console.log('JWT payload:', JSON.stringify(req.user, null, 2));
  } else {
    console.log('No JWT user found in request');
  }
  next();
});

app.use(zipkinMiddleware({tracer}));
app.use(function (err, req, res, next) {
  if (err.name === 'UnauthorizedError') {
    res.status(401).send({ message: 'invalid token' })
  }
  next(err);
})
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

// Health check endpoints (no JWT required)
app.get('/version', function (req, res) {
  res.json({ service: 'todos-api', version: '1.0.0' })
})

app.get('/health', function (req, res) {
  res.json({ status: 'healthy' })
})

const routes = require('./routes')
routes(app, {tracer, redisClient, logChannel})

app.listen(port, function () {
  console.log('todo list RESTful API server started on: ' + port)
})


const axios = require("axios");
const CircuitBreaker = require("opossum");

// Función que hace la llamada al Users API
async function getUsers() {
  const usersApiUrl = process.env.USERS_API_URL || "http://users-api:8080";
  return axios.get(`${usersApiUrl}/users`);
}

// Configuración del circuit breaker
const options = {
  timeout: 3000, // tiempo máximo por request
  errorThresholdPercentage: 50, // si 50% de requests fallan, se abre el breaker
  resetTimeout: 5000 // tiempo para intentar de nuevo
};

const breaker = new CircuitBreaker(getUsers, options);

// Endpoint que usa el breaker
app.get("/users", async (req, res) => {
  try {
    const response = await breaker.fire();
    res.json(response.data);
  } catch (err) {
    res.status(503).json({ message: "Users API unavailable. Try later." });
  }
});
