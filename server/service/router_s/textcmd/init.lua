--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gateobj = import(service_path("gateobj"))

Cmds = {}

function Cmds.open(source, handle, parm)
    local fd,addr = string.match(parm,"(%d+) ([^%s]+)")
    local ip,port = string.match(addr,"([^:]+):([^:]+)")
    local oGateMgr = global.oGateMgr
    local oGate = oGateMgr:GetGate(source)
    if oGate then
        if oGate:GetConnection(handle) then
            return
        end
        local oConnection = gateobj.NewConnection(source, handle, ip, port)
        oGate:AddConnection(oConnection)
    end
end

function Cmds.close(source, handle)
    local oGateMgr = global.oGateMgr
    local oGate = oGateMgr:GetGate(source)
    if oGate then
        if oGate:GetConnection(handle) then
            oGate:DelConnection(handle)
        end
    end
end

function Invoke(sCmd, ...)
    local f = Cmds[sCmd]
    return f(...)
end
