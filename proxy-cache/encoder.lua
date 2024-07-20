local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode

local _M = {}

function _M.json_decode(json)
    if json then
        local status, res = pcall(cjson_decode, json)
        if status then
            return res
        end
    end
end

function _M.json_encode(table)
    if table then
        local status, res = pcall(cjson_encode, table)
        if status then
            return res
        end
    end
end

return _M
