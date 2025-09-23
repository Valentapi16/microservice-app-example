'use strict';
const cache = require('memory-cache');
const CircuitBreaker = require('opossum');
const {Annotation, jsonEncoder: {JSON_V2}} = require('zipkin');

const OPERATION_CREATE = 'CREATE',
      OPERATION_DELETE = 'DELETE',
      CACHE_TTL = 3600;

class TodoController {
    constructor({tracer, redisClient, logChannel}) {
        this._tracer = tracer;
        this._redisClient = redisClient;
        this._logChannel = logChannel;
        this._cacheKeyPrefix = 'todos:user:';
        
        // Circuit Breaker options for Redis operations
        const circuitBreakerOptions = {
            timeout: 3000,          // 3 second timeout
            errorThresholdPercentage: 60,  // 60% error rate
            resetTimeout: 30000,    // 30 seconds before trying again
            rollingCountTimeout: 10000,    // 10 second rolling window
            rollingCountBuckets: 10,       // 10 buckets in the window
            volumeThreshold: 5,     // minimum requests before tripping
            name: 'Redis-CircuitBreaker'
        };

        // Circuit breakers for different Redis operations
        this._redisCacheCircuitBreaker = new CircuitBreaker(this._redisGetOperation.bind(this), circuitBreakerOptions);
        this._redisSetCircuitBreaker = new CircuitBreaker(this._redisSetOperation.bind(this), circuitBreakerOptions);
        this._redisPublishCircuitBreaker = new CircuitBreaker(this._redisPublishOperation.bind(this), circuitBreakerOptions);

        // Circuit breaker event handlers
        this._setupCircuitBreakerEvents();
    }

    _setupCircuitBreakerEvents() {
        const circuitBreakers = [this._redisCacheCircuitBreaker, this._redisSetCircuitBreaker, this._redisPublishCircuitBreaker];
        
        circuitBreakers.forEach(cb => {
            cb.on('open', () => console.log(`Circuit breaker ${cb.options.name} opened`));
            cb.on('halfOpen', () => console.log(`Circuit breaker ${cb.options.name} half-opened`));
            cb.on('close', () => console.log(`Circuit breaker ${cb.options.name} closed`));
            cb.on('fallback', (result) => console.log(`Circuit breaker ${cb.options.name} executed fallback`));
        });
    }

    // Redis operation wrappers for circuit breaker
    _redisGetOperation(key) {
        return new Promise((resolve, reject) => {
            this._redisClient.get(key, (err, result) => {
                if (err) {
                    reject(err);
                    return;
                }
                
                if (result) {
                    try {
                        resolve(JSON.parse(result));
                    } catch (parseError) {
                        reject(parseError);
                    }
                } else {
                    resolve(null);
                }
            });
        });
    }

    _redisSetOperation({key, data, ttl}) {
        return new Promise((resolve, reject) => {
            this._redisClient.setex(key, ttl, JSON.stringify(data), (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(result);
                }
            });
        });
    }

    _redisPublishOperation({channel, message}) {
        return new Promise((resolve, reject) => {
            this._redisClient.publish(channel, JSON.stringify(message), (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(result);
                }
            });
        });
    }

    // Cache Aside Pattern para LIST with Circuit Breaker
    async list(req, res) {
        const username = req.user.username;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // Circuit breaker protected Redis GET
            const cachedData = await this._redisCacheCircuitBreaker.fire(cacheKey);
            
            if (cachedData) {
                console.log(`Cache HIT for user: ${username}`);
                res.json(cachedData.items);
                return;
            }
            
            console.log(`Cache MISS for user: ${username}`);
            const data = this._getTodoDataFromMemory(username);
            
            // Circuit breaker protected Redis SET
            try {
                await this._redisSetCircuitBreaker.fire({key: cacheKey, data: data, ttl: CACHE_TTL});
            } catch (setError) {
                console.warn('Failed to cache data due to circuit breaker:', setError.message);
            }
            
            res.json(data.items);
            
        } catch (error) {
            console.error('Circuit breaker prevented Redis operation:', error.message);
            // Fallback to memory cache
            const data = this._getTodoDataFromMemory(username);
            res.json(data.items);
        }
    }

    // Cache Aside Pattern para CREATE with Circuit Breaker
    async create(req, res) {
        const username = req.user.username;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // Try to get from cache through circuit breaker
            let data;
            try {
                data = await this._redisCacheCircuitBreaker.fire(cacheKey);
            } catch (getError) {
                console.warn('Cache get failed, using memory fallback');
                data = null;
            }
            
            if (!data) {
                data = this._getTodoDataFromMemory(username);
            }
            
            // Create new todo
            const todo = {
                content: req.body.content,
                id: data.lastInsertedID
            };
            
            data.items[data.lastInsertedID] = todo;
            data.lastInsertedID++;
            
            // Update memory immediately
            this._setTodoDataInMemory(username, data);
            
            // Try to update cache through circuit breaker
            try {
                await this._redisSetCircuitBreaker.fire({key: cacheKey, data: data, ttl: CACHE_TTL});
            } catch (setError) {
                console.warn('Cache update failed due to circuit breaker:', setError.message);
            }
            
            // Log operation through circuit breaker
            this._logOperationWithCircuitBreaker(OPERATION_CREATE, username, todo.id);
            
            res.json(todo);
            
        } catch (error) {
            console.error('Error during create operation:', error);
            // Full fallback to memory-only operation
            const data = this._getTodoDataFromMemory(username);
            const todo = {
                content: req.body.content,
                id: data.lastInsertedID
            };
            data.items[data.lastInsertedID] = todo;
            data.lastInsertedID++;
            this._setTodoDataInMemory(username, data);
            
            // Try to log (may fail if circuit breaker is open)
            this._logOperationWithCircuitBreaker(OPERATION_CREATE, username, todo.id);
            res.json(todo);
        }
    }

    // Cache Aside Pattern para DELETE with Circuit Breaker
    async delete(req, res) {
        const username = req.user.username;
        const id = req.params.taskId;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // Try to get current data
            let data;
            try {
                data = await this._redisCacheCircuitBreaker.fire(cacheKey);
            } catch (getError) {
                data = null;
            }
            
            if (!data) {
                data = this._getTodoDataFromMemory(username);
            }
            
            // Delete todo
            delete data.items[id];
            
            // Update memory
            this._setTodoDataInMemory(username, data);
            
            // Try to update cache
            try {
                await this._redisSetCircuitBreaker.fire({key: cacheKey, data: data, ttl: CACHE_TTL});
            } catch (setError) {
                console.warn('Cache update failed due to circuit breaker:', setError.message);
            }
            
            // Log operation
            this._logOperationWithCircuitBreaker(OPERATION_DELETE, username, id);
            
            res.status(204).send();
            
        } catch (error) {
            console.error('Error during delete operation:', error);
            // Fallback to memory-only
            const data = this._getTodoDataFromMemory(username);
            delete data.items[id];
            this._setTodoDataInMemory(username, data);
            this._logOperationWithCircuitBreaker(OPERATION_DELETE, username, id);
            res.status(204).send();
        }
    }

    // Helper methods
    _getCacheKey(username) {
        return `${this._cacheKeyPrefix}${username}`;
    }

    // Log operation with circuit breaker protection
    _logOperationWithCircuitBreaker(opName, username, todoId) {
        this._tracer.scoped(() => {
            const traceId = this._tracer.id;
            const logMessage = {
                zipkinSpan: traceId,
                opName: opName,
                username: username,
                todoId: todoId,
            };
            
            // Use circuit breaker for publish operation
            this._redisPublishCircuitBreaker.fire({channel: this._logChannel, message: logMessage})
                .catch(error => {
                    console.warn('Logging failed due to circuit breaker:', error.message);
                });
        });
    }

    // Memory operations (unchanged)
    _getTodoDataFromMemory(userID) {
        var data = cache.get(userID);
        if (data == null) {
            data = {
                items: {
                    '1': { id: 1, content: "Create new todo" },
                    '2': { id: 2, content: "Update me" },
                    '3': { id: 3, content: "Delete example ones" }
                },
                lastInsertedID: 4
            };
            this._setTodoDataInMemory(userID, data);
        }
        return data;
    }

    _setTodoDataInMemory(userID, data) {
        cache.put(userID, data);
    }

    // Circuit breaker status endpoint
    getCircuitBreakerStatus() {
        return {
            redisCache: {
                name: this._redisCacheCircuitBreaker.options.name,
                state: this._redisCacheCircuitBreaker.opened ? 'OPEN' : 
                       this._redisCacheCircuitBreaker.halfOpen ? 'HALF_OPEN' : 'CLOSED',
                stats: this._redisCacheCircuitBreaker.stats
            },
            redisSet: {
                name: this._redisSetCircuitBreaker.options.name,
                state: this._redisSetCircuitBreaker.opened ? 'OPEN' : 
                       this._redisSetCircuitBreaker.halfOpen ? 'HALF_OPEN' : 'CLOSED',
                stats: this._redisSetCircuitBreaker.stats
            },
            redisPublish: {
                name: this._redisPublishCircuitBreaker.options.name,
                state: this._redisPublishCircuitBreaker.opened ? 'OPEN' : 
                       this._redisPublishCircuitBreaker.halfOpen ? 'HALF_OPEN' : 'CLOSED',
                stats: this._redisPublishCircuitBreaker.stats
            }
        };
    }
}

module.exports = TodoController;