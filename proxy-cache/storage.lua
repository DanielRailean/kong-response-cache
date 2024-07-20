local redis_connector = require("resty.redis.connector")
local kong = kong
local _M = {}

function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function echo_number(number)
    return number
end

local function get_fails_key(redis_host, redis_port, database, ssl, ssl_verify, username)
    return "response-cache-redis-fails-count-" ..
        redis_host .. ":"
        .. redis_port ..
        "-ssl:" .. tostring(ssl) ..
        "-ssl_verify:" .. tostring(ssl_verify) ..
        "-db:" .. database ..
        "-user:" .. (username or "user")
end


function _M:set_config(config)
    -- https://github.com/ledgetech/lua-resty-redis-connector?tab=readme-ov-file#default-parameters
    local redis_config = {
        host = config.redis.host,
        port = config.redis.port,
        password = config.redis.password,
        username = config.redis.username,
        db = config.redis.database,
        connect_timeout = config.redis.timeout.connect,
        read_timeout = config.redis.timeout.read,
        send_timeout = config.redis.timeout.send,
        keepalive_timeout = config.redis.max_idle_timeout,
        keepalive_poolsize = config.redis.pool_size,
        connection_options = {
            ssl = config.redis.ssl.enabled,
            ssl_verify = config.redis.ssl.verify,
            server_name = config.redis.ssl.server_name
        }
    }
    local sentinel_master_name = config.redis.sentinel_master_name
    if sentinel_master_name ~= nil and string.len(sentinel_master_name) > 0 then
        redis_config.master_name = sentinel_master_name
        redis_config.role = config.redis.sentinel_role
        local sentinels = config.redis.sentinel_addresses
        if sentinels then
            redis_config.sentinels = {}
            for _, sentinel in ipairs(sentinels) do
                local sentinel_host, sentinel_port = string.match(sentinel, "(.*)[:](%d*)")
                redis_config.sentinels[#redis_config.sentinels + 1] = {
                    host = sentinel_host,
                    port = sentinel_port
                }
            end
        end
    end
    self.circuit_breaker = {
        config = {},
        key = "",
        fails_count = 0,
        increment_fails = function() end,
        pass = function() end,
    }

    if config.redis.circuit_breaker.enabled then
        local key = get_fails_key(
            redis_config.host,
            redis_config.port,
            redis_config.db,
            redis_config.connection_options.ssl,
            redis_config.connection_options.ssl_verify,
            redis_config.username
        )
        self.circuit_breaker = {
            config = config.redis.circuit_breaker,
            fails_count = kong.cache:get(key, nil, echo_number, 0),
            increment_fails = function()
                local new_fails = self.circuit_breaker.fails_count + 1
                kong.cache:renew(
                    key,
                    { ttl = self.circuit_breaker.config.ttl },
                    echo_number,
                    new_fails
                )
                self.circuit_breaker.fails_count = new_fails
            end,
            pass = function()
                if (self.circuit_breaker.fails_count > self.circuit_breaker.config.fails_threshold) then
                    error("circuit breaker engaged for '" .. key .. "' , retrying in max. " ..
                        self.circuit_breaker.config.ttl .. "s")
                end
            end,
        }
    end
    self.connector = redis_connector.new(redis_config)
end

function _M:connect()
    self.circuit_breaker.pass()
    local red, err = self.connector:connect()
    if red == nil then
        kong.log.err("failed to connect to Redis: ", err)
        self.circuit_breaker.increment_fails()
        return false
    end
    self.red = red
    return true
end

function _M:close()
    local ok, err = self.connector:set_keepalive(self.red)
    if not ok then
        kong.log.err("failed to set keepalive: ", err)
        return false
    end
    return true
end

function _M:set(key, value, expire_time)
    local connected = self:connect()
    if not connected then
        return
    end
    self.circuit_breaker.pass()
    local ok, err = self.red:set(key, value)
    if not ok then
        kong.log.err("failed to set cache: ", err)
        self.circuit_breaker.increment_fails()
        return
    end
    self.red:expire(key, expire_time)
    self:close()
end

function _M:get(key)
    local connected = self:connect()
    if not connected then
        return nil
    end
    self.circuit_breaker.pass()
    local cached_value, err = self.red:get(key)
    if err then
        kong.log.err("failed to get cache: ", err)
        self.circuit_breaker.increment_fails()
        return nil, err
    end
    self:close()
    return cached_value
end

return _M
