local function validate(data, schema)
    for f_name, t in pairs(schema) do
        local val = data[f_name]
        if not val then
            return string.format("field %s must exists", f_name)
        end
        if type(val) ~= t then
            return string.format("field %s must have type %s, got %s", f_name, t, type(val))
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