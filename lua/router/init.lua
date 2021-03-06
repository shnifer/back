local errors = require 'package.errors'

local M = {}

local function if_nil_404(v, message, ...)
    if v then
        return v
    end
    return errors.not_found(message, ...)
end

local function flat_table(t)
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
    req.simple_postform = flat_table(req.postform)
    req.simple_header = flat_table(req.header)
    req.simple_query = flat_table(req.query)

    local rt = {
        users = M.users,
        rooms = M.rooms,
        targets = M.targets,
        ship = M.ship,
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

    return errors.method_not_found({req.method, req.total_path})
end

function M.targets(req)
    if req.method == "GET" then
        return app.targets:get_all()
    end
    if req.method =="POST" then
        return app.targets:shuffle()
    end

    return errors.method_not_found({req.method, req.total_path})
end

function M.ship(req)
    if req.method == "GET" then
        return if_nil_404 (app.ship:get(1), "ship{1}")
    end
    if req.method =="POST" then
        return if_nil_404 (app.ship:patch(1, req.simple_postform), "room{1}")
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
        return app.users:move(user_id, room_id)
    end

    return errors.method_not_found({req.method, req.total_path})
end

function M.debug(req)
    local first = table.remove(req.path, 1)

    if first == "reset" then
        return app.reset()
    end
    if first == "hardreset" then
        package.reload()
        return app.reset()
    end
    if first == "start" then
        return app.start()
    end
    if first == "pause" then
        return app.world.pause()
    end
    if first == "resume" then
        return app.world.resume()
    end
    if first == "stat" then
        return {
            world = app.world.stat(),
            cron = app.cron.daemon.status(),
        }
    end
    if first == "config" then
        if req.method == "GET" then
            return app.cfg
        end
        if req.method == "POST" then
            app.set_cfg(req.body);
            return
        end
    end

    return errors.method_not_found({req.method, req.total_path})
end

return M