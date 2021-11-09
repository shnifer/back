local fiber = require 'fiber'
local clock = require 'clock'
local log = require 'log'
local errors = require('package.errors')

local M = {}

M.stage={
    PREPARE = "PREPARE",
    RUNNING = "RUNNING",
    DONE    = "DONE"
}

function M.init()
    box.once('init_world_1.0', function ()
        box.schema.create_space('world', {format ={
            {name = "id", type="number"},
            {name = "stage", type="string"},
            {name = "paused", type="boolean"},
            {name = "gtime", type="number"},
            {name = "monot", type="number"},
            {name = "connected", type="boolean"},
            {name = "lastseen", type="number"}
        }})
        box.space.world:create_index('id')
        box.space.world:insert{
            1, -- id
            M.stage.PREPARE, -- stage
            false, -- paused
            0, -- gtime
            0, -- monot
            false, -- connected
            0, -- lastseen
        }
        log.info("created new world")
    end)

    local t = clock.monotonic()
    box.space.world:update({1}, {
        {"=", "connected", false},
        {"=", "monot", t}
    })
    log.info("loaded world, set mono time = %d", t)
    M.daemon = fiber.new(M._daemon)
end

function M.destroy()
    fiber.kill(M.daemon)
end

local function is_ticking(world)
    return  (not world.paused) and
            (world.connected) and
            (world.stage == M.stage.RUNNING)
end

-- calculate new time counters
function M._time(world)
    world = world or box.space.world:get{1}
    local time = clock.monotonic()
    local delta = time - world.monot
    if delta < 0 then
        log.error("MONO TIME REVERSED, was = %d , now = %d", world.monot, time)
        delta = 0
    end
    local gtime = world.gtime
    if is_ticking(world) then
        gtime = gtime+delta
    end
    return time, gtime, delta
end

-- public method to get gtime, update counters
function M.gtime()
    local world = box.space.world:get{1}
    local monot, gtime, delta = M._time(world)
    if delta>1 then
        box.space.world:update({1},{
            {"=", "monot", monot},
            {"=", "gtime", gtime}
        })
    end
    return gtime
end

-- monitor connection and set connected field
M._daemon = function()
    local max_delay = 1 -- 1 second delay

    log.info('connection monitor started')
    while true do
        local world = box.space.world:get{1}
        local delay = clock.monotonic() - world.lastseen
        if delay>max_delay and world.connected then
            local monot, gtime = M._time(world)
            box.space.world:update({1},{
                {"=", "connected", false},
                {"=", "monot", monot},
                {"=", "gtime", gtime}
            })
        end
        fiber.sleep(0.25)
    end
end

function M.set_stage(stage)
    local found = false
    for _,v in pairs(M.stage) do
        if v==stage then
            found = true
        end
    end
    if not found then
        error(string.format("stage %s is not defined", stage))
    end
    local monot, gtime = M._time()
    box.space.world:update({1}, {
        {"=", "stage", stage},
        {"=", "monot", monot},
        {"=", "gtime", gtime}
    })
end

local function set_paused(paused)
    local world = box.space.world:get{1}
    if world.paused == paused then
        return
    end
    local monot, gtime = M._time(world)
    box.space.world:update({1}, {
        {"=", "paused", paused},
        {"=", "monot", monot},
        {"=", "gtime", gtime}
    })
end

function M.pause()
    set_paused(true)
end

function M.resume()
    set_paused(false)
end

M.heartbeat = function()
    local world = box.space.world:get{1}
    local monot, gtime = M._time(world)
    box.space.world:update({1},{
        {"=", "connected", true},
        {"=", "lastseen", monot},
        {"=", "monot", monot},
        {"=", "gtime", gtime}
    })
    return {
        gtime = gtime,
        stage = world.stage,
        paused = world.paused,
    }
end

function M:reset()
    box.space.world:put{
        1, -- id
        M.stage.PREPARE, -- stage
        false, -- paused
        0, -- gtime
        0, -- monot
        false, -- connected
        0, -- lastseen
    }
end

function M:start()
    M.set_stage("RUNNING")
end

function M.stat()
    local got = box.space.world:get{1}
    local res = {
        stage = got.stage,
        paused = got.paused,
        gtime = got.gtime,
        connected = got.connected,
        is_ticking = is_ticking(got)
    }
    return res
end

return M