--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.common = import(service_path("logiccmd.common"))
Cmds.cost = import(service_path("logiccmd.cost"))
Cmds.online = import(service_path("logiccmd.online"))
Cmds.analysis = import(service_path("logiccmd.analysis"))
Cmds.overview = import(service_path("logiccmd.overview"))
Cmds.query = import(service_path("logiccmd.query"))
Cmds.backendinfo = import(service_path("logiccmd.backendinfo"))
Cmds.gmtools = import(service_path("logiccmd.gmtools"))
Cmds.business = import(service_path("logiccmd.business"))
Cmds.image = import(service_path("logiccmd.image"))
Cmds.report = import(service_path("logiccmd.report"))
Cmds.huodong = import(service_path("logiccmd.huodong"))

function Invoke(sModule, sCmd, mRecord, mData)
    local m = Cmds[sModule]
    if m then
        local f = m[sCmd]
        if f then
            return f(mRecord, mData)
        end
    end
    record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
end
