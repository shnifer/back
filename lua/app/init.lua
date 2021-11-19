local log = require 'log'
local json = require 'json'
local contains = require('package.helpers').contains

local app = {
    -- world
    world = require('app.world'),

    -- repos
    users = require('repo.users'),
    rooms = require('repo.rooms'),
    targets = require('repo.random_targets'),
    ship = require('repo.ship'),

    -- other
    cron = require ('app.cron'),
    router = require('router')
}

function app.init(config)
    local new_base = false
    box.once('init_user_v1', function()
        box.schema.user.create('myuser', {password='mypassword', if_not_exists=true})
        box.schema.user.grant('myuser', 'super', nil, nil, {if_not_exists=true})
        new_base = true
    end)

    log.info('app "game" init')
    app.cfg = config

    local init_first = {"world"}
    local init_last = {"cron","router"}

    for _,n in ipairs(init_first) do
        local mod = app[n]
        if type(mod) == 'table' and mod.init ~= nil then mod.init(config) end end

    for k, mod in pairs(app) do if type(mod) == 'table' and mod.init ~= nil and
        not contains(init_first, k) and not contains(init_last, k) then mod.init(config) end end

    for _,n in ipairs(init_last) do
        local mod = app[n]
        if type(mod) == 'table' and mod.init ~= nil then mod.init(config) end end

    if new_base then
        app.reset()
    end
end

function app.destroy()
    log.info('app "game" destroy')

    for _, mod in pairs(app) do if type(mod) == 'table' and mod.destroy ~= nil then mod.destroy() end end
end

function app.reset()
    log.info('app "game" reset')

    for _, mod in pairs(app) do if type(mod) == 'table' and mod.reset ~= nil then mod:reset() end end
end

function app.start()
    log.info('app "game" start')

    for _, mod in pairs(app) do if type(mod) == 'table' and mod.start ~= nil then mod:start() end end
end

function app.get_handler(str)
    local parts = string.split(str, ".")
    local p = app
    for _,v in ipairs(parts) do
        p = p[v]
        if not p then
            return
        end
    end
    if type(p)~="function" then
        p = nil
        log.error("handler %s is not a function, but %s", str, type(p))
    end
    return p
end

function app.set_cfg(cfg_str)
    assert(type(cfg_str)=="string")
    local new_cfg = json.decode(cfg_str)
end


package.reload:register(app)
rawset(_G, 'app', app)
return app
