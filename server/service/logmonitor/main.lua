local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local logmonitor = import(service_path("logmonitor"))

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    global.oLogMonitor = logmonitor.NewLogMonitor()

    skynet.register ".logmonitor"
    interactive.Send(".dictator", "common", "Register", {
        type = ".logmonitor",
        addr = MY_ADDR,
    })

    record.info("logmonitor service booted")
end)
