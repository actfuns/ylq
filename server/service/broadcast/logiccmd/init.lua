--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.channel = import(service_path("logiccmd.channel"))
Cmds.notify = import(service_path("logiccmd.notify"))
Cmds.gonggao = import(service_path("logiccmd.gonggao"))

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
