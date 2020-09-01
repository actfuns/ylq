--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.assist = import(service_path("logiccmd.assist"))
Cmds.item = import(service_path("logiccmd.item"))
Cmds.common = import(service_path("logiccmd.common"))
Cmds.partner = import(service_path("logiccmd.partner"))
Cmds.backend = import(service_path("logiccmd.backend"))
Cmds.skill = import(service_path("logiccmd.skill"))
Cmds.fuli = import(service_path("logiccmd.fuli"))

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