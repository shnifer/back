local M = require("package.new_space")("rooms")

M.validate_schema = {
    id = "int",
    name = "string",
    damage = "number",
    temperature = "number",
    cooler = "number",
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

return M