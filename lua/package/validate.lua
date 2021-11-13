local function validate_int(val, fname)
    if math.floor(val) ~= val then
        return fname.." must be int, but is "..val
    end
end

local function parse_pattern(pattern)
    local res = {
        allow_empty = false,
        type = pattern
    }
    if type(pattern) == "table" then
        res.allow_empty = pattern.allow_empty or false
        res.type = "table"
    end
    if type(pattern) == "string" then
        if string.sub(pattern, 1, 1) == "*" then
            res.type = string.sub(pattern, 2)
            res.allow_empty = true
        end
    end
    if res.type == "int" then
        res.type = "number"
        res.validate_f = validate_int
    end
    return res
end

local function validate(data, schema)
    for f_name, pattern_str in pairs(schema) do
        local pattern = parse_pattern(pattern_str)
        local val = data[f_name]
        if not val and not pattern.allow_empty then
            return string.format("field %s must exists", f_name)
        end
        if val then
            if type(val) ~= pattern.type then
                return string.format("field %s must have type %s, got %s", f_name,  pattern.type, type(val))
            end
            if pattern.validate_f then
                local err = pattern.validate_f(val, f_name)
                if err then
                    return err
                end
            end
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