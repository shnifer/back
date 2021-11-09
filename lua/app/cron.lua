local fiber = require 'fiber'
local log = require 'log'

local M = {}

function M.init(cfg)
    box.once('init_cron_v1', function()
        box.schema.create_space('cron', {format={
            {name = "name", type = "string"},
            {name = "next", type = "number"},
            {name = "last", type = "number"},
            {name = "period", type = "number"},
            {name = "handler", type = "string"}
        }})
        box.space.cron:create_index('name', {parts = {1, "string"}})
        box.space.cron:create_index('next', {parts = {2, "number"}, unique = false})
    end)

    M.cfg = cfg.cron
    assert(M.cfg, "config should have cron section")
    assert(M.cfg.jobs, "config should have cron.jobs section")
    local gtime = app.world.gtime()
    for name, opts in pairs(M.cfg.jobs) do
        assert(opts.handler, "cron job "..name.." must have handler")
        local period = opts.period or 1
        box.space.cron:upsert({name, gtime+period, gtime, period, opts.handler}, {
            {"=", "period", period},
            {"=", "handler", opts.handler},
        })
    end

    M.daemon = fiber.new(M._daemon)
end

function M.destroy()
    fiber.kill(M.daemon)
end

M._daemon = function ()
    local max_period = M.cfg.max_period or 5 -- перепроверяем не реже, чем
    local min_period = M.cfg.min_period or 0.1 -- перепроверяем не чаще, чем

    while true do
        local job = box.space.cron.index.next:select({0}, {iterator = 'ge', limit = 1})[1]
        if not job then
            fiber.sleep(max_period) -- no job at all, but may be added later
            goto continue
        end
        local gtime = app.world.gtime()
        if gtime < job.next then
            local wait = job.next-gtime
            if wait>max_period then
                wait = max_period
            end
            if wait<min_period then
                wait = min_period
            end
            fiber.sleep(wait)
            goto continue
        end

        local next = job.next + job.period
        box.space.cron:update({job.name}, {
            {"=", "next", next},
            {"=", "last", gtime},
        })
        local dt = gtime - job.last
        local handler = app.get_handler(job.handler)
        if not handler then
            log.error("no handler found for job %s, handler %s", job.name, job.handler)
            goto continue
        end

        local ok, got = pcall(handler , dt)
        if not ok then
            log.error("error calling cron job %s (handler=%s), err: %s", job.name, job.handler, got)
        end
        fiber.yield()
        ::continue::
    end
end

return M