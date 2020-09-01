local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local routercmd = import(service_path("routercmd.init"))
local reportmgr = import(service_path("reportmgr"))
local iNo = ...

skynet.start(function()
    interactive.Dispatch(logiccmd)
    router.DispatchC(routercmd)
    net.Dispatch()

    global.oReportMgr = reportmgr.NewReportMgr()
    global.oReportMgr:Init()

    skynet.register(".datareport"..iNo)

    interactive.Send(".dictator", "common", "Register", {
        type = ".datareport",
        addr = MY_ADDR,
    })

    record.info("datareport service booted")
end)
