local cjson        = require "cjson.safe"
-- https://github.com/openresty/lua-resty-redis
local redis        = require "resty.redis"
local kong         = kong
local ngx          = ngx
local type         = type
local setmetatable = setmetatable

local _M           = {}

local function is_present(str)
  return str and str ~= "" and str ~= ngx.null
end

local function get_connection(opts)
  local red, err_redis = redis:new()

  if err_redis then
    kong.log.err("error connecting to Redis: ", err_redis);
    return nil, err_redis
  end

  -- https://github.com/openresty/lua-resty-redis?tab=readme-ov-file#connect
  local redis_opts = {
    pool = opts.database and opts.host .. ":" .. opts.port .. ":" .. opts.database,
    ssl = opts.tls.enabled,
    ssl_verify = opts.tls.verify,
    server_name = opts.tls.server_name,
    pool_size = opts.pool_size
  }

  red:set_timeouts(opts.timeout.connect, opts.timeout.send, opts.timeout.read)

  -- https://github.com/openresty/lua-resty-redis?tab=readme-ov-file#connect
  local ok, err = red:connect(opts.host, opts.port, redis_opts)
  if not ok then
    kong.log.err("failed to connect to Redis: ", err)
    return nil, err
  end

  local times, err2 = red:get_reused_times()
  if err2 then
    kong.log.err("failed to get connect reused times: ", err2)
    return nil, err
  end

  if times == 0 then
    if is_present(opts.password) then
      local ok3, err3 = red:auth(opts.password)
      if not ok3 then
        kong.log.err("failed to auth Redis: ", err3)
        return nil, err
      end
    end

    if opts.database ~= 0 then
      local ok4, err4 = red:select(opts.database)
      if not ok4 then
        kong.log.err("failed to change Redis database: ", err4)
        return nil, err
      end
    end
  end
  kong.log[opts.log_level]("connection reused " .. times .. " times")

  return red
end

function _M.new(opts)
  local self = {
    opts = opts,
  }

  return setmetatable(self, {
    __index = _M,
  })
end

local function store_cache_value(_, opts, key, req_obj, req_ttl)
  local ttl = req_ttl or opts.ttl
  local instance, err_conn = get_connection(opts)
  if err_conn or not instance then
    return nil, err_conn
  end

  instance:init_pipeline(2)
  instance:hmset(key, req_obj)
  instance:expire(key, ttl)

  local _, err = instance:commit_pipeline()
  if err then
    kong.log.err("failed to commit the cache value to Redis: ", err)
    return err
  end

  local ok, err2 = instance:set_keepalive(opts.idle_timeout_ms)
  if not ok then
    kong.log.err("failed to set Redis keepalive: ", err2)
    return err2
  end
end

function _M:store(key, req_obj, req_ttl)
  if type(key) ~= "string" then
    return nil, "key must be a string"
  end

  req_obj.headers = cjson.encode(req_obj.headers)
  ngx.timer.at(0, store_cache_value, self.opts, key, req_obj, req_ttl)

  return true
end

function _M:fetch(key)
  if type(key) ~= "string" then
    return nil, "key must be a string"
  end

  local instance, err_conn = get_connection(self.opts)
  if err_conn or not instance then
    return nil, err_conn
  end

  local cache_req, err = instance:hgetall(key)
  if cache_req and #cache_req < 2 then
    if not err then
      -- this specific string is needed
      return nil, "request object not in cache"
    else
      return nil, err
    end
  end

  local ok, err2 = instance:set_keepalive(self.opts.idle_timeout_ms)
  if not ok then
    kong.log.err("failed to set Redis keepalive: ", err2)
    return nil, err2
  end

  cache_req     = instance:array_to_hash(cache_req)
  -- everything returned will be a string
  cache_req.headers   = cjson.decode(cache_req.headers)
  cache_req.version   = tonumber(cache_req.version)
  cache_req.status    = tonumber(cache_req.status)
  cache_req.body_len  = tonumber(cache_req.body_len)
  cache_req.timestamp = tonumber(cache_req.timestamp)
  cache_req.ttl       = tonumber(cache_req.ttl)
  return cache_req
end

function _M:purge(key)
  local instance, err_conn = get_connection(self.opts)
  if err_conn or not instance then
    return nil, err_conn
  end

  local _, err = instance:del(key)
  if err then
    return nil, err
  end
  return true
end

-- can't see it being used in handler, but it's present in the mem strategy
-- function _M:touch(key, req_ttl, timestamp)
--   if type(key) ~= "string" then
--     return nil, "key must be a string"
--   end

--   local req_json, err = self.dict:get(key)
--   if not req_json then
--     if not err then
--       return nil, "request object not in cache"

--     else
--       return nil, err
--     end
--   end

--   local req_obj = cjson.decode(req_json)
--   if not req_obj then
--     return nil, "could not decode request object"
--   end

--   req_obj.timestamp = timestamp or time()

--   return _M:store(key, req_obj, req_ttl)
-- end


function _M:flush()
  local instance, err_conn = get_connection(self.opts)
  if err_conn or not instance then
    return nil, err_conn
  end

  local _, err = instance:flushdb("async")
  if err then
    kong.log.err("failed to flush the database from Redis: ", err)
    return nil, err
  end
  return true
end

return _M
