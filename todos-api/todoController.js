'use strict';
const cache = require('memory-cache'); // Mantener como fallback
const {Annotation, 
    jsonEncoder: {JSON_V2}} = require('zipkin');

const OPERATION_CREATE = 'CREATE',
      OPERATION_DELETE = 'DELETE',
      CACHE_TTL = 3600; // 1 hora en segundos

class TodoController {
    constructor({tracer, redisClient, logChannel}) {
        this._tracer = tracer;
        this._redisClient = redisClient;
        this._logChannel = logChannel;
        this._cacheKeyPrefix = 'todos:user:';
    }

    // Cache Aside Pattern para LIST
    async list(req, res) {
        const username = req.user.username;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // 1. Check Cache First (Cache Aside Pattern)
            const cachedData = await this._getFromCache(cacheKey);
            
            if (cachedData) {
                console.log(`Cache HIT for user: ${username}`);
                res.json(cachedData.items);
                return;
            }
            
            // 2. Cache MISS - Get from "database" (memory in this case)
            console.log(`Cache MISS for user: ${username}`);
            const data = this._getTodoDataFromMemory(username);
            
            // 3. Store in Cache for next time
            await this._setInCache(cacheKey, data, CACHE_TTL);
            
            res.json(data.items);
            
        } catch (error) {
            console.error('Cache error, falling back to memory:', error);
            // Fallback to memory cache if Redis fails
            const data = this._getTodoDataFromMemory(username);
            res.json(data.items);
        }
    }

    // Cache Aside Pattern para CREATE
    async create(req, res) {
        const username = req.user.username;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // 1. Get current data (from cache or memory)
            let data = await this._getFromCache(cacheKey);
            if (!data) {
                data = this._getTodoDataFromMemory(username);
            }
            
            // 2. Create new todo
            const todo = {
                content: req.body.content,
                id: data.lastInsertedID
            };
            
            data.items[data.lastInsertedID] = todo;
            data.lastInsertedID++;
            
            // 3. Update both memory and cache
            this._setTodoDataInMemory(username, data);
            await this._setInCache(cacheKey, data, CACHE_TTL);
            
            // 4. Log operation
            this._logOperation(OPERATION_CREATE, username, todo.id);
            
            res.json(todo);
            
        } catch (error) {
            console.error('Cache error during create:', error);
            // Fallback to memory-only operation
            const data = this._getTodoDataFromMemory(username);
            const todo = {
                content: req.body.content,
                id: data.lastInsertedID
            };
            data.items[data.lastInsertedID] = todo;
            data.lastInsertedID++;
            this._setTodoDataInMemory(username, data);
            this._logOperation(OPERATION_CREATE, username, todo.id);
            res.json(todo);
        }
    }

    // Cache Aside Pattern para DELETE
    async delete(req, res) {
        const username = req.user.username;
        const id = req.params.taskId;
        const cacheKey = this._getCacheKey(username);
        
        try {
            // 1. Get current data
            let data = await this._getFromCache(cacheKey);
            if (!data) {
                data = this._getTodoDataFromMemory(username);
            }
            
            // 2. Delete todo
            delete data.items[id];
            
            // 3. Update both memory and cache
            this._setTodoDataInMemory(username, data);
            await this._setInCache(cacheKey, data, CACHE_TTL);
            
            // 4. Log operation
            this._logOperation(OPERATION_DELETE, username, id);
            
            res.status(204).send();
            
        } catch (error) {
            console.error('Cache error during delete:', error);
            // Fallback to memory-only operation
            const data = this._getTodoDataFromMemory(username);
            delete data.items[id];
            this._setTodoDataInMemory(username, data);
            this._logOperation(OPERATION_DELETE, username, id);
            res.status(204).send();
        }
    }

    // Cache Helper Methods
    _getCacheKey(username) {
        return `${this._cacheKeyPrefix}${username}`;
    }

    // Get data from Redis Cache
    _getFromCache(key) {
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

    // Set data in Redis Cache
    _setInCache(key, data, ttl) {
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

    // Invalidate cache (useful for future operations)
    _invalidateCache(username) {
        return new Promise((resolve, reject) => {
            const cacheKey = this._getCacheKey(username);
            this._redisClient.del(cacheKey, (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    console.log(`Cache invalidated for user: ${username}`);
                    resolve(result);
                }
            });
        });
    }

    // Log operation (unchanged)
    _logOperation(opName, username, todoId) {
        this._tracer.scoped(() => {
            const traceId = this._tracer.id;
            this._redisClient.publish(this._logChannel, JSON.stringify({
                zipkinSpan: traceId,
                opName: opName,
                username: username,
                todoId: todoId,
            }));
        });
    }

    // Memory operations (renamed for clarity)
    _getTodoDataFromMemory(userID) {
        var data = cache.get(userID);
        if (data == null) {
            data = {
                items: {
                    '1': {
                        id: 1,
                        content: "Create new todo",
                    },
                    '2': {
                        id: 2,
                        content: "Update me",
                    },
                    '3': {
                        id: 3,
                        content: "Delete example ones",
                    }
                },
                lastInsertedID: 4 // Changed to 4 for next ID
            };

            this._setTodoDataInMemory(userID, data);
        }
        return data;
    }

    _setTodoDataInMemory(userID, data) {
        cache.put(userID, data);
    }
}

module.exports = TodoController;