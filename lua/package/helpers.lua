local json = require 'json'

local M = {}

function M.patch(data, patch, allow_new)
    assert(type(data)=="table")
    assert(type(patch)=="table")
    for f_name, val in pairs (patch) do
        if data[f_name]~=nil or allow_new then
            local t = type (data[f_name])
            if t == "number" then
                val = tonumber(val)
            end
            if t == "string" then
                val = tostring(val)
            end
            if t == "table" then
                val = json.decode(val)
            end
            data[f_name] = val
        else
            return nil, f_name
        end
    end
    return data
end

function M.contains(arr, elem)
    for i,v in ipairs(arr) do
        if v==elem then
            return i
        end
    end
    return false
end

return M