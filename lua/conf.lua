local bg
local logger
if os.getenv('FG') then
    bg = false
    logger = '| tee'
end

box = {
    listen = os.getenv("LISTEN") or 3301,
    memtx_memory = 500 * 1024 * 1024, -- 0.5 GB
    vinyl_memory = 1024*1024, -- 1 MB
    background = bg,
    log = logger,
    checkpoint_interval = 60,
    checkpoint_count = 2
}

app = {
    users = {
        start_room = 3,
        default = {
            name = "",
            max_ap = 400,
            cur_ap = 400,
            wounds = 0,
            stim = 0,
            waste = 0,
            room = 0,
            tactic = 1,
            engineer = 1,
            operative = 1,
            navigator = 1,
            science = 1,
        },
        list = {
            {
                name = "Алиса",
                tactic = 3,
            },
            {
                name = "Боб",
                operative = 2,
                engineer = 2,
            },
            {
                name = "Карл",
            }
        },
        job = {
            ap_regen = 50,
            stim_start = 300,
            stim_drop = 100,
            waste_start = 600,
            waste_drop = 100,
        }
    },
    rooms = {
        default = {
            damage = 0,
            temperature = 25,
            cooler = 10,
            damage_amplify = 1,
            ammo = 0,
            energy = 0,
            cpu = 0,
            fuel = 0,
            max_ammo = 100,
            max_energy = 100,
            max_cpu = 100,
            max_fuel = 100,
            inc_ammo = 0,
            inc_energy = 0,
            inc_cpu = 0,
            inc_fuel = 0,
        },
        start_room = 1,
        list = {
            {
                name = "Мостик",
            },
            {
                name = "Левый борт",
            },
            {
                name = "Правый борт",
            },
            {
                name = "Носовой",
            },
            {
                name = "Кормовой",
            },
            {
                name = "Трюм",
                cooler = 500,
            },
            {
                name = "Медблок",
            },
        }
    },
    targets = {
        count = 5,
    },
    ship = {
        default = {
            id = 1,
            shield_forward = 100,
            shield_left = 100,
            shield_right = 100,
            shield_back = 100,

            structure_damage = 0,
            structure_max = 300,
            turn_speed = 1,
            course = 0,
            accelerate = 1,
            speed = 0,
            max_speed = 0,
        },
    },
    cron = {
        max_period = 1,
        min_period = 0.03,
        jobs = {
            users = {
                handler = "users.cron",
                period = 1,
            },
            roooms = {
                handler = "rooms.cron",
                period = 1,
            },
            targets = {
                handler = "targets.cron",
                period = 0.033,
            }
        }
    },
}
