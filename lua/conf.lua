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
    cron = {
        max_period = 1,
        min_period = 0.03,
        jobs = {
            users = {
                handler = "users.cron"
            }
        }
    },
}
