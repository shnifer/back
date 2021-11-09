local M = {}

local json = require 'json'

function M.new(code, error_type, message, ...)
    if type(message)=="table" then
        message = json.encode(message)
    end
    if type(message)~="string" then
        message = tostring(message)
    end
    return {
        HTTP_CODE = code,
        ERROR_TYPE = error_type,
        MESSAGE = string.format(message, ...)
    }
end

function M.not_found(message, ...)
    return M.new(404, "not_found", message, ...)
end

function M.method_not_found(message, ...)
    return M.new(404, "method_not_found", message, ...)
end
function M.validate(message, ...)
    return M.new(400, "validate", message, ...)
end

return M