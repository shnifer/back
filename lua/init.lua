require 'strict'.on()
require 'package.reload'

local conf_path = os.getenv('CONF')
if conf_path == nil then
    conf_path = './conf.lua'
end
local conf = require('package.config')(conf_path)

local app = require 'app'
if app ~= nil and app.init ~= nil then
    local ok, res = xpcall(
            function()
                return app.init(conf.get('app'))
            end,
            function(err)
                print(err .. '\n' .. debug.traceback())
                os.exit(1)
            end
    )
end

inspect = require('inspect')

if tonumber(os.getenv('FG')) == 1 then
    if pcall(require('console').start) then
        os.exit(0)
    end
end
