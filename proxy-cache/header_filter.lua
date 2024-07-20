local validators = require 'kong.plugins.response-cache.validators'

local _M = {}

function _M.execute(config)
    if not validators.check_response_code(config.response_code, ngx.status) then
        ngx.header['X-Cache-Status'] = 'BYPASS'
    end
end

return _M
