local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local texthandle = require "base.texthandle"
local router = require "base.router"
local res = require "base.res"
local record = require "public.record"
local serverdefines = require "public.serverdefines"

require "skynet.manager"

local textcmd = import(service_path("textcmd.init"))
local netcmd = import(service_path("netcmd.init"))
local logiccmd = import(service_path("logiccmd.init"))
local gateobj = import(service_path("gateobj"))

local iNo = ...

skynet.start(function()
    interactive.Dispatch(logiccmd)
    texthandle.Dispatch(textcmd)
    router.DispatchR(netcmd)

    global.oGateMgr = gateobj.NewGateMgr()
    global.oGateMgr:Init()

    iNo = tonumber(iNo)
    local ports = split_string(ROUTER_S_PORTS,",")
    local iPort = tonumber(ports[iNo])
    local oGate = gateobj.NewGate(iPort)
    global.oGateMgr:AddGate(oGate)

    skynet.register (".router_s"..iNo)
    interactive.Send(".dictator", "common", "Register", {
        type = ".router_s",
        addr = MY_ADDR,
    })

    record.info("router_s service booted")
end)
