local M = require("package.new_space")("users")

M.validate_schema = {
    id = "number",
    name = "string",
    max_ap = "number",
    cur_ap = "number",
    wounds = "number",
    stim = "number",
    waste = "number",
    prof = "table"
}

M.init_cfg = function (cfg)
    assert(cfg, "config should have users section")
    assert(cfg.default, "config should have users.default section")
    assert(cfg.job, "config should have users.job section")
    cfg.job.ap_regen = cfg.job.ap_regen or 0
    cfg.job.stim_start = cfg.job.stim_start or 300
    cfg.job.stim_drop = cfg.job.stim_drop or 1
    cfg.job.waste_start = cfg.job.waste_start or 600
    cfg.job.waste_drop = cfg.job.waste_drop or 1
end

function M:reset()
    self:refill_from_cfg_list()
end

function M:cron_update(data, dt)
    local cfg = self.cfg.job
    local dm = dt/60
    data.cur_ap = math.min(data.max_ap, data.cur_ap+dm*cfg.ap_regen)
    if data.stim>0 then
        data.stim = math.max(0, data.stim - dm*cfg.stim_drop)
        if data.stim == 0 then
            data.waste = cfg.waste_start
        end
    end
    if data.waste>0 then
        data.waste = math.max(0, data.waste - dm*cfg.waste_drop)
    end
    return data
end

function M:add_def ()
    local id = self:next_id()
    local data = {}
    for k,v in pairs(self.cfg.default) do
        data[k] = v
    end
    data.id = id
    local err = self:validate(data)
    if err then
        return err
    end
    self:space():insert{id, data}
    return data
end

return M