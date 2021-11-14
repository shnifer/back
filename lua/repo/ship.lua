local M = require("package.new_space")("ship")

M.validate_schema = {
    id = "int",
    shield_forward = "int",
    shield_left = "int",
    shield_right = "int",
    shield_back = "int",

    structure_damage = "int",
    structure_max = "int",
    turn_speed = "number",
    course = "number",
    accelerate = "number",
    speed = "number",
    max_speed = "number",
}

M.init_cfg = function (cfg)
    assert(cfg, "config should have ship section")
    assert(cfg.default, "config should have ship.default section")
end

function M:reset()
    self:truncate()
    self:insert(self.cfg.default)
end

return M