local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local texthandle = require "base.texthandle"
local res = require "base.res"
local record = require "public.record"
local router = require "base.router"
local serverdefines = require "public.serverdefines"

require "skynet.manager"

local textcmd = import(service_path("textcmd.init"))
local netcmd = import(service_path("netcmd.init"))
local logiccmd = import(service_path("logiccmd.init"))
local gateobj = import(service_path("gateobj"))
local routercmd = import(service_path("routercmd.init"))
local punishmgr = import(service_path("punishmgr"))

skynet.start(function()
    net.Dispatch(netcmd)
    interactive.Dispatch(logiccmd)
    texthandle.Dispatch(textcmd)
    router.DispatchC(routercmd)

    global.oGateMgr = gateobj.NewGateMgr()
    global.oGateMgr:Init()
    local sPorts = serverdefines.get_gateway_ports()
    local lPorts = split_string(sPorts, ",", tonumber)
    for _, v in ipairs(lPorts) do
        local oGate = gateobj.NewGate(v)
        global.oGateMgr:AddGate(oGate)
    end
    global.oPunishMgr = punishmgr.NewPunishMgr()
    global.oPunishMgr:Init()

    skynet.register ".login"
    interactive.Send(".dictator", "common", "Register", {
        type = ".login",
        addr = MY_ADDR,
    })

    record.info("login service booted")
end)
