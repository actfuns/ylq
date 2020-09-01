local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local reportproxy = import(service_path("reportproxy"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()
    router.DispatchC()

    global.oReportProxy = reportproxy.NewReportProxy()
    global.oReportProxy:Init()

    skynet.register ".report"

    interactive.Send(".dictator", "common", "Register", {
        type = ".report",
        addr = MY_ADDR,
    })

    record.info("report service booted")
end)
