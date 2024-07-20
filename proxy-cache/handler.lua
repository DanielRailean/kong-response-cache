local access = require 'kong.plugins.response-cache.access'
local body_filter = require 'kong.plugins.response-cache.body_filter'
local header_filter = require 'kong.plugins.response-cache.header_filter'
local kong = kong
local ngx = ngx
local ProxyCaching = {}

ProxyCaching.PRIORITY = 100
ProxyCaching.VERSION = '2.0.0'

function ProxyCaching:access(config)
    local ok, err = pcall(access.execute, config)
    if not ok then
        kong.log.crit(err)
    end
end

function ProxyCaching:header_filter(config)
    local ok, err = pcall(header_filter.execute, config)
    if not ok then
        kong.log.crit(err)
    end
end

function ProxyCaching:body_filter(config)
    local rt_body_chunks = ngx.ctx.rt_body_chunks
    local is_miss =  ngx.header['X-Cache-Status'] == 'Miss'
    if rt_body_chunks and is_miss then
        local ok, err = pcall(body_filter.execute, config)
        if not ok then
            kong.log.crit(err)
        end
    end
end

return ProxyCaching
