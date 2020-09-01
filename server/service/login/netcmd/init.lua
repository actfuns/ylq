--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

Cmds = {}

Cmds.login = import(service_path("netcmd.login"))
Cmds.other = import(service_path("netcmd.other"))

function Invoke(sModule, sCmd, fd, mData)
    local m = Cmds[sModule]
    if m then
        local f = m[sCmd]
        if f then
            local oGateMgr = global.oGateMgr
            local oConnection = oGateMgr:GetConnection(fd)
            if oConnection then
                return f(oConnection, mData)
            end
        else
            record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
        end
    else
        record.error(string.format("Invoke fail %s %s %s %s", MY_SERVICE_NAME, MY_ADDR, sModule, sCmd))
    end
end
