local M = require("package.new_space")("targets")

M.validate_schema = {
    id = "int",
    name = "string",
    pos = "table",
    vel = "table",
    size = "number",
    color = "table",
}

M.init_cfg = function (cfg)
    assert(cfg, "config should have targets section")
    assert(cfg.count, "config should have targets.count value")
end

function M:reset()
    self:shuffle();
end

local function rand_vel(s)
    local min_v, max_v =5, 15
    local spread = max_v - min_v
    if not s then
        s = 1
        if math.random()>0.5 then
            s = -1
        end
    end
    if s>0 then
        return math.random()*spread + min_v
    else
        return - math.random()*spread - min_v
    end
end

function M:shuffle()
    math.randomseed(os.time())

    local names = {"Ack","Beer","Charlie","Don","Edward","Freddie","Gee","Harry","Ink","Johnnie","King","London",
                   "Emma","Nuts","Oranges","Pip","Queen","Robert","Essex","Toc","Uncle","Vic","William","X-ray",
                   "Yorker","Zebra"}
    local function rand_pos()
        return {math.random()*200-100,math.random()*200-100}
    end

    self:truncate();
    for i = 1, self.cfg.count do
        self:insert{
            id=i,
            name = names[i] or (tostring(i)),
            pos = rand_pos(),
            vel = {rand_vel(), rand_vel()},
            size =3+math.random()*10,
            color = {math.random(255), math.random(255), math.random(255)},
        }
    end
end

function M:cron_update(data, dt)
    data.pos[1] = data.pos[1] + dt*data.vel[1]
    data.pos[2] = data.pos[2] + dt*data.vel[2]

    if data.pos[1]>100 and data.vel[1]>0 then
        data.vel[1] = rand_vel(-1)
    end
    if data.pos[1]<(-100) and data.vel[1]<0 then
        data.vel[1] = rand_vel(1)
    end
    if data.pos[2]>100 and data.vel[2]>0 then
        data.vel[2] = rand_vel(-1)
    end
    if data.pos[2]<(-100) and data.vel[2]<0 then
        data.vel[2] = rand_vel(1)
    end

    return data
end

return M