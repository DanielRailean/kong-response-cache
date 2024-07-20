local Storage = require 'kong.plugins.response-cache.storage'
local validators = require 'kong.plugins.response-cache.validators'
local Cache = require 'kong.plugins.response-cache.cache'
local Encoder = require 'kong.plugins.response-cache.encoder'
local ngx = ngx
local kong = kong
local floor            = math.floor
local time             = ngx.time
local _M = {}

local function reset_res_headers(res)
    res.headers["Age"] = nil
    res.headers["X-Cache-Status"] = nil
    res.headers["X-Cache-Key"] = nil
end

local function set_res_header(res, header, value, conf)
    if ngx.var.http_kong_debug or conf.response_headers[header] then
        res.headers[header] = value
    end
end

local function render_from_cache(cache_key, cached_value, conf)
    local response = Encoder.json_decode(cached_value)
    reset_res_headers(response)
    ngx.ctx.KONG_PROXIED = true

    set_res_header(response, "Age", floor(time() - response.timestamp), conf)
    set_res_header(response, "X-Cache-Status", "Hit", conf)
    set_res_header(response, "X-Cache-Key", cache_key, conf)
    return kong.response.exit(response.status, response.content, response.headers)
end

function _M.execute(conf)
    local storage = Storage:new()
    local cache = Cache:new()
    storage:set_config(conf)
    cache:set_config(conf)

    if not validators.check_request_method() then
        ngx.header['X-Cache-Status'] = 'Bypass'
        return
    end
    local cache_key = cache:generate_cache_key(ngx.req, ngx.var)
    local cached_value, err = storage:get(cache_key)
    if not (cached_value and cached_value ~= ngx.null) then
        ngx.header['X-Cache-Status'] = 'Miss'
        ngx.ctx.cache_key = cache_key
        ngx.ctx.rt_body_chunks = {}
        ngx.ctx.rt_body_chunk_number = 1
        return
    end
    return render_from_cache(cache_key, cached_value, conf)
end

return _M
