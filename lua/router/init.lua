local errors = require 'package.errors'

local M = {}

local function if_nil_404(v, message, ...)
    if v then
        return v
    end
    return errors.not_found(message, ...)
end

local function simplify(t)
    local simple = {}
    if not t then
        return simple
    end
    for k,v in pairs(t) do
        if type(v) == "table" then
            simple[k] = v[1]
        else
            simple[k] = v
        end
    end
    return simple
end

function M.universal(req)
    req.total_path = table.copy(req.path)
    req.simple_postform = simplify(req.postform)
    req.simple_header = simplify(req.header)
    req.simple_query = simplify(req.query)

    local rt = {
        users = M.users,
        rooms = M.rooms,
        act   = M.act,
        debug = M.debug,
    }
    local firstPart = table.remove(req.path,1)
    local route_f = rt[firstPart]
    if route_f then
        return route_f(req)
    end
    return errors.method_not_found({req.method, req.total_path})
end

function M.users(req)
    local first = table.remove(req.path, 1)
    local number = tonumber(first)

    if req.method == "GET" then
        if not first then
            local got = app.users:get_all()
            return got
        end
        if number then
            return if_nil_404 (app.users:get(number), "users{%d}", number)
        end
    end
    if req.method == "POST" then
        if not first then
            return app.users:add_def()
        end
        if number then
            return if_nil_404 (app.users:patch(number, req.simple_postform), "users{%d}", number)
        end
    end
    if req.method == "DELETE" then
        if number then
            return if_nil_404(app.users:delete(number), "users{%d}", number)
        end
    end

    return errors.method_not_found({req.method, req.total_path})
end

function M.rooms(req)
    local first = table.remove(req.path, 1)
    local number = tonumber(first)

    if req.method == "GET" then
        if not first then
            local got = app.rooms:get_all()
            return got
        end
        if number then
            return if_nil_404 (app.rooms:get(number), "room{%d}", number)
        end
    end
    if req.method == "POST" then
        if number then
            return if_nil_404 (app.rooms:patch(number, req.simple_postform), "room{%d}", number)
        end
    end
end

function M.act(req)
    local first = table.remove(req.path, 1)

    if first == "move" then
        local user_id = tonumber(req.simple_postform.user_id)
        local room_id = tonumber(req.simple_postform.room_id)
        if not user_id then
            return errors.validate("need user_id in post form")

        end
        if not room_id then
            return errors.validate("need room_id in post form")
        end
        return app.rooms:move_user(user_id, room_id)
    end
end

function M.debug(req)
    local first = table.remove(req.path, 1)

    if first == "reset" then
        return app.reset()
    end
    if first == "start" then
        return app.start()
    end
    if first == "stat" then
        return {
            world = app.world.stat(),
        }
    end

    return errors.method_not_found({req.method, req.total_path})
end

return M