local M = require("package.new_space")("rooms")

local contains = require('package.helpers').contains

M.validate_schema = {
    id = "number",
    name = "string",
    damage = "number",
    temperature = "number",
    cooler = "number",
    roomers = "table",
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

function M:start()
    local users = app.users:get_all()
    local ids = {}
    for _, user in ipairs(users) do
        table.insert(ids, user.id)
    end
    table.sort(ids)
    self:modify_all_tx(function(room)
        if room.id == self.cfg.start_room then
            room.roomers = ids
        else
            room.roomers = {}
        end
        return room
    end)
end

function M:move_user(user_id, room_id)
    self:modify_all_tx(function(room)
        local roomers = room.roomers
        if room.id == room_id then
            -- new room
            if contains(roomers, user_id) then
                return nil
            end
            table.insert(roomers, user_id)
            table.sort(roomers)
            return room
        else
            -- other room
            local i = contains(roomers, user_id)
            if not i then
                return nil
            end
            table.remove(roomers, i)
            return room
        end
    end)
end

return M