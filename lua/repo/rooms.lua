local M = require("package.new_space")("rooms")

M.validate_schema = {
    id = "int",
    name = "string",
    damage = "number",
    temperature = "number",
    cooler = "number",
    damage_amplify = "number",

    ammo = "number",
    energy = "number",
    cpu = "number",
    fuel = "number",

    max_ammo = "number",
    max_energy = "number",
    max_cpu = "number",
    max_fuel = "number",

    inc_ammo = "number",
    inc_energy = "number",
    inc_cpu = "number",
    inc_fuel = "number",
}

M.init_cfg = function (cfg)
    assert(cfg, "config should have rooms section")
    assert(cfg.default, "config should have rooms.default section")
    assert(cfg.list, "config should have rooms.list section")
    assert(cfg.start_room, "config should have rooms.start_room value")
end

function M:reset()
    self:refill_from_cfg_list()
end

function M:get(id)
    local roomers = app.users:get_roomers()
    local got = self.__index.get(self, id)
    if not got then
        return
    end
    got.roomers = roomers[got.id] or {}
    return got
end

function M:get_all(id)
    local roomers = app.users:get_roomers()
    local got = self.__index.get_all(self, id)
    for _, v in ipairs(got) do
        v.roomers = roomers[v.id] or {}
    end
    return got
end

function M:cron_update(data, dt)
    local dm = dt/60
    data.ammo = math.min(data.ammo + data.inc_ammo * dm, data.max_ammo)
    data.energy = math.min(data.energy + data.inc_energy * dm, data.max_energy)
    data.cpu = math.min(data.cpu + data.inc_cpu * dm, data.max_cpu)
    data.fuel = math.min(data.fuel + data.inc_fuel * dm, data.max_fuel)
    return data
end

return M