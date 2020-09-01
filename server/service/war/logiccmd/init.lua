--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.war = import(service_path("logiccmd.war"))
Cmds.worldboss = import(service_path("logiccmd.worldboss"))
Cmds.orgfuben = import(service_path("logiccmd.orgfuben"))
Cmds.common = import(service_path("logiccmd.common"))
Cmds.fieldboss = import(service_path("logiccmd.fieldboss"))
Cmds.msattack = import(service_path("logiccmd.msattack"))

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
