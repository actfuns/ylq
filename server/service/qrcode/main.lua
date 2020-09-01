local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local texthandle = require "base.texthandle"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"
local textcmd = import(service_path("textcmd.init"))
local netcmd = import(service_path("netcmd.init"))
local routercmd = import(service_path("routercmd.init"))
local gateobj = import(service_path("gateobj"))
local qrcodemgr = import(service_path("qrcodemgr"))
local logiccmd = import(service_path("logiccmd.init"))

local iPort = ...

skynet.start(function()
    net.Dispatch(netcmd)
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)
    texthandle.Dispatch(textcmd)

    global.oGateMgr = gateobj.NewGateMgr()
    local oGate = gateobj.NewGate(iPort)
    global.oGateMgr:AddGate(oGate)

    local sServiceKey = string.format("qrcode%d",iPort)
    global.oQRCodeMgr = qrcodemgr.NewQRCodeMgr(sServiceKey)
    global.oQRCodeMgr:Init()

    skynet.register(string.format(".qrcode%d",iPort))
    interactive.Send(".dictator", "common", "Register", {
        type = ".qrcode",
        addr = MY_ADDR,
    })

    record.info("qrcode service booted")
end)
