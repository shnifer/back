local errors = require 'package.errors'

local class = {}
class.__index = class

function class:space()
    return box.space[self._name]
end

function class:next_id()
    return box.sequence[self._name..'_id']:next()
end

function class:new_init()
    local name = self._name
    self.init = function(cfg)
        box.once('init_'..name, function()
            box.schema.sequence.create(name..'_id')
            box.schema.create_space(name, {format={
                {name = "id", type = "unsigned"},
                {name = "data", type = "map"}
            }})
            box.space[name]:create_index('id')
        end)

        self.cfg = cfg[name]
        if type(self.init_cfg) == "function" then
            self.init_cfg(self.cfg)
        end
        if type(self.on_init) == "function" then
            self:on_init()
        end
    end
end

function class:truncate()
    self:space():truncate()
end

function class:len()
    return self:space():len()
end

function class:get_all ()
    local all = self:space():select{}
    local result = {}
    for _,v in ipairs(all) do
        local data = v.data
        table.insert(result, data)
    end
    return result
end

function class:get (id)
    local got = self:space():get{id}
    return got and got.data
end

-- inserts new, use class:next_id() if data.id is not passed
function class:insert(data)
    if not data.id then
        data.id = self:next_id()
    end
    local err = self:validate(data)
    if err then
        return err
    end
    self:space():insert{data.id, data}
    return data
end

-- get all record, pass each in f . If f function returns nil then pass, else save returned data into same record.
-- record delete is not supported
function class:modify_all_tx(f)
    box.atomic(function ()
        self:modify_all(f)
    end)
end

function class:modify_all(f)
    local items = self:get_all()
    for _,item in ipairs(items) do
        local new = f(item)
        if new then
            new.id = item.id
            self:space():put{new.id, new}
        end
    end
end

-- truncate and uses class.cfg.default and class.cfg.list to fill repo.
function class:refill_from_cfg_list()
    assert(self.cfg)
    assert(self.cfg.default)
    assert(self.cfg.list)

    local max_id = 0
    box.atomic(function()
        self:truncate()
        local def = self.cfg.default
        local list = self.cfg.list
        for i,list_data in ipairs(list) do
            local data = {}
            for k,v in pairs (def) do
                data[k]=v
            end
            for k,v in pairs (list_data) do
                data[k]=v
            end
            data.id = data.id or i
            max_id = math.max(max_id, data.id)
            self:insert(data)
        end
        box.sequence[self._name..'_id']:set(max_id)
    end)
end

function class:patch (id, patch)
    local data = self:get (id)
    if not data then
        return
    end
    patch[id] = nil
    local err_field
    data, err_field = require('package.helpers').patch(data, patch)
    if err_field then
        return errors.validate("can't patch field %s in %s", err_field, self._name)
    end
    local err = self:validate(data)
    if err then
        return err
    end
    self:space():update({id}, {{"=", "data", data}})
    return data
end

function class:delete (id)
    return self:space():delete{id}
end

function class:new_cron()
    self.cron = function(dt)
        if type(self.cron_update) == "function" then
            box.atomic(self._cron, dt)
        end
    end

    self._cron = function(dt)
        local all = self:get_all()
        for _,data in ipairs(all) do
            data = self:cron_update(data, dt)
            local good = true
            local err = self:validate(data)
            if err then
                log.error(self._name..".cron validate error on new data %s", data)
                good = false
            end
            self:space():put({data.id, data})
        end
    end
end

function class:validate(data)
    assert(type(data)=="table")
    if not self.validate_schema then
        return nil
    end
    return require('package.validate')(data, self.validate_schema)
end

local new_space = function(name)
    local space = setmetatable({ _name = name }, class)
    space:new_init()
    space:new_cron()
    return space
end

-- Could be added new properties:

-- space:cron_update(data, dt)
-- space.init_cfg(cfg)
-- space.validate_schema

return new_space