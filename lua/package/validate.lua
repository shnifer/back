local function validate(data, schema)
    for f_name, pattern in pairs(schema) do
        local vtype = pattern
        local allow_empty = false
        if string.sub(pattern, 1, 1) == "*" then
            vtype = string.sub(pattern, 2)
            allow_empty = true
        end
        local val = data[f_name]
        if not val and not allow_empty then
            return string.format("field %s must exists", f_name)
        end
        if val and type(val) ~= vtype then
            return string.format("field %s must have type %s, got %s", f_name, vtype, type(val))
        end
    end
end

local M = function(data, schema)
    local message = validate(data, schema)
    if message then
        return require("package.errors").validate(message)
    end
end

return M